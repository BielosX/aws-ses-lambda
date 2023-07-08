import lombok.SneakyThrows;
import lombok.experimental.Delegate;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import org.thymeleaf.templatemode.TemplateMode;
import org.thymeleaf.templateresolver.ClassLoaderTemplateResolver;

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class EmailTemplateEngine {
    @Delegate
    private final TemplateEngine engine;

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
        Map<String, Object> variables = new HashMap<>();
        for (Field field: object.getClass().getDeclaredFields()) {
            field.setAccessible(true);
            variables.put(field.getName(), field.get(object));
        }
        return engine.process(template, new Context(Locale.US, variables));
    }
}
