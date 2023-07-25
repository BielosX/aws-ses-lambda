import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import java.util.Locale;
import java.util.Map;
import lombok.SneakyThrows;
import lombok.experimental.Delegate;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import org.thymeleaf.templatemode.TemplateMode;
import org.thymeleaf.templateresolver.ClassLoaderTemplateResolver;

public class EmailTemplateEngine {
  @Delegate private final TemplateEngine engine;
  private final Gson gson = new Gson();

  public EmailTemplateEngine() {
    ClassLoaderTemplateResolver resolver = new ClassLoaderTemplateResolver();
    resolver.setPrefix("/templates/");
    resolver.setSuffix(".html");
    resolver.setTemplateMode(TemplateMode.HTML);
    this.engine = new TemplateEngine();
    engine.setTemplateResolver(resolver);
  }

  @SneakyThrows
  public String process(String template, Object object) {
    String json = gson.toJson(object);
    Map<String, Object> variables =
        gson.fromJson(json, new TypeToken<Map<String, Object>>() {}.getType());
    return engine.process(template, new Context(Locale.US, variables));
  }
}
