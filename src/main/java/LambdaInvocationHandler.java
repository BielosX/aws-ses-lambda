import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

public class LambdaInvocationHandler implements RequestHandler<InvocationRequest, String> {
    private final static String TEMPLATE = "welcome";
    private final EmailTemplateEngine engine = new EmailTemplateEngine();

    @Override
    public String handleRequest(InvocationRequest input, Context context) {
        return engine.process(TEMPLATE, input);
    }
}
