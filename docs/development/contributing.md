# Contributing Guide

## Getting Started

### Repository Setup
```bash
git clone <repository-url>
cd RISC-V-Processor-Verilog
```

### Development Environment
```bash
# Install Vivado 2023.2+
# Install SymbiYosys for formal verification
pip install symbiyosys
```

## Contribution Types

### Bug Reports
1. Check existing issues
2. Create new issue with:
   - Vivado version
   - Test that fails
   - Steps to reproduce
   - Expected vs actual behavior

### Feature Requests
1. Check roadmap in `VERSION_ROADMAP.md`
2. Create issue with:
   - Use case
   - Proposed interface
   - Implementation approach

### Code Contributions

#### 1. Fork and Branch
```bash
git checkout -b feature/new-instruction
```

#### 2. Make Changes
- Follow coding standards (`docs/development/coding-standards.md`)
- Add tests for new functionality
- Update documentation

#### 3. Run Tests
```bash
make test-all
make lint
```

#### 4. Submit Pull Request
- Clear description
- Reference related issues
- Include test results

## Code Review Checklist

### Code Quality
- [ ] Follows coding standards
- [ ] No lint warnings
- [ ] Meaningful variable names
- [ ] Adequate comments

### Testing
- [ ] All existing tests pass
- [ ] New tests added for changes
- [ ] Coverage maintained or improved

### Documentation
- [ ] Updated relevant docs
- [ ] Changelog updated
- [ ] No TODO/FIXME without issue reference

### Formal Verification
- [ ] SVA assertions pass
- [ ] Coverage maintained or improved

## Release Process

### Version Bump
```bash
# Update VERSION_ROADMAP.md
# Update CHANGELOG.md
# Tag release
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin v1.1.0
```

## Code of Conduct

- Be respectful
- Constructive feedback
- No discrimination
- Follow project guidelines

## License

MIT License - see `LICENSE` file