public record SESLambdaResponse(String disposition) {
  public static SESLambdaResponse continueRule() {
    return new SESLambdaResponse("CONTINUE");
  }

  public static SESLambdaResponse stopRule() {
    return new SESLambdaResponse("STOP_RULE");
  }
}
