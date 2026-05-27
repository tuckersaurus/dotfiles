/** @type {import("stylelint").Config} */
export default {
  extends: ["stylelint-config-standard-scss"],
  ignoreFiles: [
    "**/*.intellisense.css",
    "**/wwwroot/**/*.css"
  ],
  customSyntax: "postcss-scss",
  plugins: ["stylelint-scss"],
  rules: {
    "at-rule-no-unknown": null,
    "scss/at-rule-no-unknown": true
  }
};
