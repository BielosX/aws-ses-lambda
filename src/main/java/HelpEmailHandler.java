import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;
import com.google.gson.Gson;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
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
                    String request = content.content();
                    String body = engine.process(TEMPLATE, new EmailModel(from, request));
                    emailService.sendEmail(fromAddress, from, subject, body);
                });
        return null;
    }
}
