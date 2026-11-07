const sanitizeText = (value) =>
  String(value)
    .replace(/\beyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g, "[REDACTED_TOKEN]")
    .replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, "[REDACTED_EMAIL]")
    .replace(/(?<!\w)\+?\d[\d\s().-]{5,}\d(?!\w)/g, "[REDACTED_NUMBER]")
    .replace(
      /\b(password|token|authorization|secret|phoneNumber|email|number|name)\s*[:=]\s*(['"])(.*?)\2/gi,
      "$1=[REDACTED]"
    )
    .replace(
      /\b(password|token|authorization|secret|phoneNumber|email|number|name)\s*[:=]\s*(['"]?)[^,\s;'"]+\2/gi,
      "$1=[REDACTED]"
    );

const safeUrl = (value) => {
  const url = new URL(value, "http://localhost");

  for (const key of url.searchParams.keys()) {
    if (
      /password|token|authorization|secret|email|phone|number|name|address|birth|dob|member.?id|user.?id|^id$/i.test(
        key
      )
    ) {
      url.searchParams.set(key, "[REDACTED]");
    }
  }

  return sanitizeText(
    `${url.pathname}${url.search}`.replace(/\b[0-9a-f]{24}\b/gi, "[REDACTED_ID]")
  );
};

const logError = (prefix, context, error) => {
  let details;
  if (error instanceof Error) {
    details = {
      type: error.name,
      message: sanitizeText(error.message),
      stack: sanitizeText(error.stack || ""),
    };
  } else {
    let value;
    try {
      value = typeof error === "string" ? error : JSON.stringify(error);
    } catch {
      value = String(error);
    }
    details = {
      type: typeof error,
      details: sanitizeText(value ?? String(error)),
    };
  }

  console.error(`${prefix} ${context}`, JSON.stringify(details));
};

module.exports = { logError, safeUrl };
