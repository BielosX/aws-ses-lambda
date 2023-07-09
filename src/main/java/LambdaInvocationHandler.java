import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

public class LambdaInvocationHandler implements RequestHandler<InvocationRequest, Void> {
    private final static String TEMPLATE = "welcome";
    private final static String SUBJECT = "Welcome";
    private final EmailTemplateEngine engine = new EmailTemplateEngine();
    private final EmailService emailService = new EmailService();

    @Override
    public Void handleRequest(InvocationRequest input, Context context) {
        String fromDomain = System.getenv("FROM_DOMAIN");
        String fromAddress = "info@" + fromDomain;
        String body = engine.process(TEMPLATE, input);
        emailService.sendEmail(fromAddress, input.email(), SUBJECT, body);
        return null;
    }
}
