module.exports = {
  env: {
    browser: true,
    commonjs: true,
    es2021: true,
    mocha: true,
  },
  extends: [
    'airbnb-base',
  ],
  parserOptions: {
    ecmaVersion: 'latest',
  },
  rules: {
    'max-len': ['error', 240],
    'comma-dangle': ['error', 'always-multiline'],
    'semi': ['error', 'always'],
    'indent': ['error', 2],
    'quotes': ['error', 'single'],
    'quote-props': ['error', 'consistent-as-needed'],
    'import/extensions': 'off',
    'import/prefer-default-export': 'off',
    'import/no-cycle': 'off',
    'import/no-extraneous-dependencies': ['error', {
      devDependencies: true,
      packageDir: [__dirname, `${__dirname}/src`],
    }],
  },
  overrides: [{
    files: [
      '*.spec.js',
      '*.test.js',
    ],
    rules: {
      'import/no-extraneous-dependencies': 'off',
    },
  }],
};
