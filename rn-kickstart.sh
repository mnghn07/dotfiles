npx react-native init NewRNProject --template react-native-template-typescript
yarn add --dev prettier eslint eslint-config-prettier @react-native-community/eslint-config husky lint-staged
# new file
yarn add babel-plugin-module-resolver
touch react-native.config.js
echo > "module.exports = {
  project: {
    ios: {},
    android: {},
  },
  assets: ["./src/assets/fonts/"], // stays the same
  dependencies: {
    "react-native-vector-icons": {
      platforms: {
        ios: null,
      },
    },
  },
};
" > react-native.config.js
