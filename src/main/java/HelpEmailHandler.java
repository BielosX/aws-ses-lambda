import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;
import com.google.gson.Gson;
import jakarta.mail.BodyPart;
import jakarta.mail.Message;
import jakarta.mail.Multipart;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.List;
import java.util.Properties;
import java.util.UUID;

@Slf4j
public class HelpEmailHandler implements RequestHandler<SNSEvent, Void> {
    private final static String TEMPLATE = "help";
    private final EmailTemplateEngine engine = new EmailTemplateEngine();
    private final EmailService emailService = new EmailService();
    private final Gson gson = new Gson();

    private record KeyValuePair(String name, String value) {}
    private record Mail(List<KeyValuePair> headers) {}
    private record Content(String content, Mail mail) {}
    private record EmailModel(String email, String request) {}

    private static String getFrom(List<KeyValuePair> keyValuePairs) {
        return keyValuePairs.stream()
                .filter(k -> k.name().equals("From"))
                .map(KeyValuePair::value)
                .findFirst()
                .orElse("");
    }

    @SneakyThrows
    private static String getEmailContent(String payload) {
        Session session = Session.getInstance(new Properties());
        InputStream stream = new ByteArrayInputStream(payload.getBytes());
        Message message = new MimeMessage(session, stream);
        Multipart multipart = (Multipart) message.getContent();
        int parts = multipart.getCount();
        log.info("MIME parts: {}", parts);
        String result = "";
        for (int idx = 0; idx < parts; idx++) {
            BodyPart bodyPart = multipart.getBodyPart(idx);
            log.info("Found part of type: {}", bodyPart.getContentType());
            if (bodyPart.getContentType().contains("text/html")) {
                result = (String)bodyPart.getContent();
                break;
            }
            if (bodyPart.getContentType().contains("text/plain")) {
                result = (String) bodyPart.getContent();
            }
        }
        return result;
    }

    @Override
    public Void handleRequest(SNSEvent input, Context context) {
        String fromDomain = System.getenv("FROM_DOMAIN");
        String fromAddress = "help@" + fromDomain;
        input.getRecords()
                .forEach(record -> {
                    Content content = gson.fromJson(record.getSNS().getMessage(), Content.class);
                    String from = getFrom(content.mail().headers());
                    log.info("Email received from {}", from);
                    String subject = "Help request: " + UUID.randomUUID();
                    String request = getEmailContent(content.content());
                    String body = engine.process(TEMPLATE, new EmailModel(from, request));
                    emailService.sendEmail(fromAddress, from, subject, body);
                });
        return null;
    }
}
