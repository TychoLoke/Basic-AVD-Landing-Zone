# Contributing to AVD Demo

Thank you for considering contributing to this project! 🎉

## How to Contribute

### Reporting Bugs

- Use GitHub Issues
- Include clear description and steps to reproduce
- Include deployment logs if applicable
- Specify Azure region and subscription type

### Suggesting Enhancements

- Use GitHub Issues with "enhancement" label
- Explain use case and expected benefit
- Consider cost implications

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly (deployment + validation)
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request

## Development Guidelines

### Bicep Code Style

- Use 2 spaces for indentation
- Add comments for complex logic
- Follow Azure naming conventions
- Use parameters for configurable values

### Testing

Before submitting:
- ✅ Validate Bicep: `az bicep build --file bicep/main.bicep`
- ✅ Test deployment in a clean subscription
- ✅ Verify all features work (SSO, connections, etc.)
- ✅ Test cleanup script
- ✅ Update documentation if needed

### Documentation

- Update README.md for user-facing changes
- Update TROUBLESHOOTING.md for new issues/solutions
- Add examples where helpful
- Keep language clear and concise

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn

## Questions?

Use GitHub Discussions for questions and ideas.

Thank you for contributing! 🚀
