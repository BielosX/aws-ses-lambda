import jakarta.mail.Message.RecipientType;
import jakarta.mail.Multipart;
import jakarta.mail.Session;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeBodyPart;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.internet.MimeMultipart;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Properties;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.ses.SesClient;
import software.amazon.awssdk.services.ses.model.*;

@Slf4j
public class EmailService {
  private static final String CHARSET = StandardCharsets.UTF_8.name();
  private final SesClient client = SesClient.create();

  public void sendEmail(String from, String to, String subject, String htmlBody) {
    Message message =
        Message.builder()
            .subject(Content.builder().data(subject).charset(CHARSET).build())
            .body(
                Body.builder()
                    .html(Content.builder().data(htmlBody).charset(CHARSET).build())
                    .build())
            .build();
    SendEmailRequest request =
        SendEmailRequest.builder()
            .message(message)
            .source(from)
            .destination(Destination.builder().toAddresses(to).build())
            .build();
    log.info("Sending email from {} to {} with subject {}", from, to, subject);
    client.sendEmail(request);
  }

  public record EmailAttachment(byte[] content, String contentType, String name) {}

  @SneakyThrows
  public void sendTextEmailWithAttachments(
      String from, String to, String subject, String textBody, List<EmailAttachment> attachments) {
    Session session = Session.getInstance(new Properties());
    jakarta.mail.Message email = new MimeMessage(session);
    email.setFrom(new InternetAddress(from));
    email.setRecipient(RecipientType.TO, new InternetAddress(to));
    email.setSubject(subject);
    email.setText(textBody);
    Multipart multipart = new MimeMultipart();
    for (EmailAttachment attachment : attachments) {
      MimeBodyPart bodyPart = new MimeBodyPart();
      bodyPart.setDisposition("attachment;" + "filename=" + "\"" + attachment.name() + "\"");
      bodyPart.setContent(attachment.content(), attachment.contentType());
      multipart.addBodyPart(bodyPart);
    }
    email.setContent(multipart);
    ByteArrayOutputStream stream = new ByteArrayOutputStream();
    email.writeTo(stream);
    RawMessage message =
        RawMessage.builder().data(SdkBytes.fromByteArray(stream.toByteArray())).build();
    SendRawEmailRequest request =
        SendRawEmailRequest.builder().rawMessage(message).source(from).destinations(to).build();
    log.info("Sending email with {} attachments from {} to {}", attachments.size(), from, to);
    client.sendRawEmail(request);
  }
}
