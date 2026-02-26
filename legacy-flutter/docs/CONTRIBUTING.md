# Contributing to Sada

Thank you for your interest in contributing to Sada! This document provides guidelines and instructions for contributing to the project.

---

## 🤝 Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different viewpoints and experiences

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.4+
- Dart SDK 3.10.4+
- Android Studio / VS Code
- Git

### Setup

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/sada.git
   cd sada
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Generate localization**
   ```bash
   flutter gen-l10n
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📝 Development Workflow

### Branch Naming Convention

- **Feature**: `feature/feature-name`
  - Example: `feature/add-file-sharing`
- **Bugfix**: `bugfix/issue-description`
  - Example: `bugfix/fix-memory-leak`
- **Hotfix**: `hotfix/critical-issue`
  - Example: `hotfix/security-patch`
- **Documentation**: `docs/documentation-update`
  - Example: `docs/update-readme`

### Commit Message Format

Use conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(chat): add message encryption
fix(auth): resolve PIN verification issue
docs(readme): update installation instructions
```

---

## 🏗️ Code Style

### Dart Style Guide

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `dart format` before committing
- Maximum line length: 100 characters
- Use meaningful variable names (Arabic comments for clarity)

### File Organization

```
lib/
├── core/
│   ├── database/
│   ├── network/
│   ├── router/
│   ├── security/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── features/
    ├── auth/
    ├── chat/
    ├── groups/
    ├── home/
    └── settings/
```

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`
- **Constants**: `UPPER_SNAKE_CASE`
- **Private**: `_leadingUnderscore`

### Code Comments

- Use Arabic comments for business logic (per user preference)
- Use English comments for technical explanations
- Document complex algorithms
- Explain "why" not just "what"

---

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/chat/chat_test.dart

# Run with coverage
flutter test --coverage
```

### Writing Tests

- **Unit Tests**: Test business logic in isolation
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete user flows

**Example:**
```dart
test('should encrypt message correctly', () {
  final service = EncryptionService(mockKeyManager);
  final encrypted = service.encryptMessage('Hello', sharedKey);
  expect(encrypted, isNotEmpty);
});
```

---

## 🌐 Localization

### Adding New Strings

1. **Add to ARB files** (`l10n/app_en.arb` and `l10n/app_ar.arb`):
   ```json
   {
     "newKey": "New String",
     "@newKey": {
       "description": "Description of the string"
     }
   }
   ```

2. **Generate localization**:
   ```bash
   flutter gen-l10n
   ```

3. **Use in code**:
   ```dart
   Text(l10n.newKey)
   ```

### Translation Guidelines

- **English**: Professional, clear, concise
- **Arabic**: Professional Arabic, RTL-aware
- **Kurdish**: Latin script (not Arabic script)
- **Placeholders**: Use function parameters for dynamic values

---

## 🔒 Security Considerations

### Before Submitting

- ✅ No hardcoded secrets or API keys
- ✅ All sensitive data in FlutterSecureStorage
- ✅ No logging of sensitive information
- ✅ Input validation and sanitization
- ✅ Error handling for edge cases

### Security Review

Security-sensitive changes require:
- Code review by maintainers
- Security audit checklist
- Documentation of threat model

---

## 📋 Pull Request Process

### Before Submitting

1. **Update Documentation**
   - Update README if needed
   - Update relevant docs in `docs/`
   - Add code comments

2. **Run Tests**
   ```bash
   flutter test
   flutter analyze
   ```

3. **Check Linting**
   ```bash
   flutter pub run custom_lint
   ```

4. **Format Code**
   ```bash
   dart format lib/
   ```

### PR Checklist

- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Localization strings added (if needed)
- [ ] No linter errors
- [ ] All tests passing
- [ ] Security considerations addressed

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How was this tested?

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
```

---

## 🐛 Reporting Bugs

### Bug Report Template

```markdown
## Description
Clear description of the bug

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Flutter Version: [e.g., 3.10.4]
- Dart Version: [e.g., 3.10.4]
- Device: [e.g., Android 13, Pixel 6]
- App Version: [e.g., 1.0.0]

## Screenshots
If applicable

## Logs
Relevant log output
```

---

## 💡 Feature Requests

### Feature Request Template

```markdown
## Feature Description
Clear description of the feature

## Use Case
Why is this feature needed?

## Proposed Solution
How should this work?

## Alternatives Considered
Other approaches considered

## Additional Context
Any other relevant information
```

---

## 🎯 Priority Areas

### High Priority

- **Native Mesh Implementation**: WiFi P2P and Bluetooth LE
- **Message Protocol**: Mesh message format and routing
- **Database Integration**: Drift/Hive for message storage
- **Security Audits**: Code review and penetration testing

### Medium Priority

- **Testing**: Unit tests, integration tests
- **Performance**: Optimization and profiling
- **Documentation**: API documentation, tutorials
- **Accessibility**: Screen reader support, contrast improvements

### Low Priority

- **UI Polish**: Animations, transitions
- **Additional Features**: File sharing, voice messages
- **Platform Support**: iOS implementation

---

## 📞 Getting Help

### Resources

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and discussions
- **Documentation**: Check `docs/` folder first

### Questions?

- Open a GitHub Discussion
- Check existing issues
- Review documentation

---

## 🙏 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Credited in release notes
- Appreciated by the community!

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Sada! 🎉

