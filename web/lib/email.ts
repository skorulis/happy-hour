import { Resend } from "resend";

const DEFAULT_FROM = "DuskRoute <noreply@mail.duskroute.com>";

function getFromAddress(): string {
  return process.env.EMAIL_FROM?.trim() || DEFAULT_FROM;
}

export async function sendVerificationEmail({
  to,
  otp,
  verifyUrl,
}: {
  to: string;
  otp: string;
  verifyUrl: string;
}): Promise<void> {
  const subject = "Verify your DuskRoute email";
  const text = [
    "Verify your DuskRoute email address.",
    "",
    `Your verification code is: ${otp}`,
    "",
    `Or open this link to verify: ${verifyUrl}`,
    "",
    "If you did not create a DuskRoute account, you can ignore this email.",
  ].join("\n");

  const html = `
    <p>Verify your DuskRoute email address.</p>
    <p>Your verification code is:</p>
    <p style="font-size:24px;font-weight:700;letter-spacing:0.15em;">${otp}</p>
    <p><a href="${verifyUrl}">Click here to verify your email</a></p>
    <p style="color:#666;font-size:14px;">If you did not create a DuskRoute account, you can ignore this email.</p>
  `.trim();

  const apiKey = process.env.RESEND_API_KEY?.trim();
  if (!apiKey) {
    console.info(
      `[email] RESEND_API_KEY unset — verification for ${to}: code=${otp} url=${verifyUrl}`,
    );
    return;
  }

  const resend = new Resend(apiKey);
  const { error } = await resend.emails.send({
    from: getFromAddress(),
    to,
    subject,
    text,
    html,
  });

  if (error) {
    console.error("[email] Failed to send verification email:", error);
    throw new Error(error.message ?? "Failed to send verification email.");
  }
}

export async function sendPasswordResetEmail({
  to,
  resetUrl,
}: {
  to: string;
  resetUrl: string;
}): Promise<void> {
  const subject = "Reset your DuskRoute password";
  const text = [
    "Reset your DuskRoute password.",
    "",
    `Open this link to choose a new password: ${resetUrl}`,
    "",
    "If you did not request a password reset, you can ignore this email.",
  ].join("\n");

  const html = `
    <p>Reset your DuskRoute password.</p>
    <p><a href="${resetUrl}">Click here to choose a new password</a></p>
    <p style="color:#666;font-size:14px;">If you did not request a password reset, you can ignore this email.</p>
  `.trim();

  const apiKey = process.env.RESEND_API_KEY?.trim();
  if (!apiKey) {
    console.info(
      `[email] RESEND_API_KEY unset — password reset for ${to}: url=${resetUrl}`,
    );
    return;
  }

  const resend = new Resend(apiKey);
  const { error } = await resend.emails.send({
    from: getFromAddress(),
    to,
    subject,
    text,
    html,
  });

  if (error) {
    console.error("[email] Failed to send password reset email:", error);
    throw new Error(error.message ?? "Failed to send password reset email.");
  }
}
