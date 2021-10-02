module.exports = {
  env: {
    es2021: true,
    node: true,
    es6: true
  },
  extends: ['eslint:recommended', 'plugin:prettier/recommended'],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module'
  },
  plugins: ['prettier'],
  rules: {
    'no-await-in-loop': 'off',
    'no-console': 'off'
  },
  globals: {
    __dirname: true
  }
};
