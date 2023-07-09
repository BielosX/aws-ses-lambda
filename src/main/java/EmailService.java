import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.services.ses.SesClient;
import software.amazon.awssdk.services.ses.model.Body;
import software.amazon.awssdk.services.ses.model.Content;
import software.amazon.awssdk.services.ses.model.Destination;
import software.amazon.awssdk.services.ses.model.Message;
import software.amazon.awssdk.services.ses.model.SendEmailRequest;

import java.nio.charset.StandardCharsets;

@Slf4j
public class EmailService {
    private final static String CHARSET = StandardCharsets.UTF_8.name();
    private final SesClient client = SesClient.create();

    public void sendEmail(String from, String to, String subject, String htmlBody) {
        Message message = Message.builder()
                .subject(Content.builder()
                        .data(subject)
                        .charset(CHARSET)
                        .build())
                .body(Body.builder()
                        .html(Content.builder()
                                .data(htmlBody)
                                .charset(CHARSET)
                                .build())
                        .build())
                .build();
        SendEmailRequest request = SendEmailRequest.builder()
                .message(message)
                .source(from)
                .destination(Destination.builder()
                        .toAddresses(to)
                        .build())
                .build();
        log.info("Sending email from {} to {} with subject {}", from, to, subject);
        client.sendEmail(request);
    }
}
