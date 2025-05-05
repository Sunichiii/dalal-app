module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    // Enforce 2 spaces for indentation
    "indent": ["error", 2],

    // Enforce double quotes for strings
    "quotes": ["error", "double", {"allowTemplateLiterals": true}],

    // Enforce maximum line length of 80 characters
    "max-len": ["error", {"code": 80}],

    // Enforce no multiple spaces
    "no-multi-spaces": ["error"],

    // Ensure no space before and after curly braces in objects
    "object-curly-spacing": ["error", "never"],

    // Ensure parentheses around arrow function arguments
    "arrow-parens": ["error", "always"],

    // Prevent restricted global variables (name and length)
    "no-restricted-globals": ["error", "name", "length"],

    // Prefer arrow callbacks
    "prefer-arrow-callback": "error",
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
