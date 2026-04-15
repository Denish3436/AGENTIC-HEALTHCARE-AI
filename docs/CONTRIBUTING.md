# Contributing to Healthcare AI Platform

Thank you for your interest in contributing to the Healthcare AI Platform! This document provides guidelines and best practices for contributing to this Azure-based healthcare project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Requirements](#testing-requirements)
6. [Security Guidelines](#security-guidelines)
7. [Pull Request Process](#pull-request-process)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of background or experience level.

### Expected Behavior

- Use welcoming and inclusive language
- Respect differing viewpoints and experiences
- Accept constructive criticism gracefully
- Focus on what's best for the healthcare community
- Show empathy towards other contributors

---

## Getting Started

### Prerequisites

1. **Azure Account**: Active Azure subscription
2. **Development Tools**:
   - Git
   - Docker Desktop
   - Visual Studio Code (recommended)
   - Azure CLI
   - kubectl
   - Python 3.11+
   - Node.js 18+

3. **Azure DevOps Access**: Request access from the project maintainers

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/agentic-healthcare-ai.git
cd agentic-healthcare-ai

# Create a feature branch
git checkout -b feature/your-feature-name

# Set up environment
cp env.template .env
# Edit .env with your local Azure credentials

# Install dependencies
cd ui && npm install
cd ../crewai_fhir_agent && pip install -r requirements.txt
cd ../autogen_fhir_agent && pip install -r requirements.txt
```

---

## Development Workflow

### Branch Strategy

We follow **GitFlow**:

```
main (production)
  └── develop (integration)
       ├── feature/new-feature
       ├── feature/another-feature
       └── hotfix/critical-fix
```

### Branch Naming Convention

- `feature/` - New features (e.g., `feature/add-radiology-agent`)
- `bugfix/` - Bug fixes (e.g., `bugfix/fix-fhir-connection`)
- `hotfix/` - Production hotfixes (e.g., `hotfix/security-patch`)
- `docs/` - Documentation updates (e.g., `docs/update-deployment-guide`)
- `refactor/` - Code refactoring (e.g., `refactor/optimize-database-queries`)

### Commit Message Format

Follow **Conventional Commits**:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `security`: Security improvements

**Examples:**

```bash
feat(agents): add radiology specialist agent

Implement new radiology agent with DICOM integration
and image analysis capabilities using Azure Cognitive Services.

Closes #123

---

fix(fhir): resolve patient search pagination issue

Fixed bug where patient search was not properly handling
pagination tokens from Azure Health Data Services.

Fixes #456

---

security(auth): implement Azure AD B2C integration

Enhanced authentication with Azure AD B2C for better
security and compliance with HIPAA requirements.

BREAKING CHANGE: Old authentication method deprecated
```

---

## Coding Standards

### Python Code Style

**Follow PEP 8** with these tools:

```bash
# Format code
black .

# Lint code
flake8 .
pylint **/*.py

# Type checking
mypy .
```

**Example:**

```python
from typing import Dict, List, Optional
from dataclasses import dataclass


@dataclass
class PatientAssessment:
    """Patient assessment data model."""
    
    patient_id: str
    assessment_type: str
    findings: List[Dict[str, str]]
    recommendations: Optional[str] = None
    
    def validate(self) -> bool:
        """Validate assessment data."""
        return bool(self.patient_id and self.assessment_type)
```

### TypeScript/React Code Style

**Follow Airbnb Style Guide**:

```bash
# Lint code
npm run lint

# Format code
npm run format

# Type check
npm run type-check
```

**Example:**

```typescript
interface PatientData {
  id: string;
  name: string;
  dateOfBirth: string;
  medicalRecordNumber: string;
}

const PatientCard: React.FC<{ patient: PatientData }> = ({ patient }) => {
  const [isLoading, setIsLoading] = useState<boolean>(false);
  
  const handleAssessment = async (): Promise<void> => {
    setIsLoading(true);
    try {
      await startAssessment(patient.id);
    } catch (error) {
      console.error('Assessment failed:', error);
    } finally {
      setIsLoading(false);
    }
  };
  
  return (
    <Card>
      <CardContent>
        <Typography variant="h6">{patient.name}</Typography>
        <Button onClick={handleAssessment} disabled={isLoading}>
          Start Assessment
        </Button>
      </CardContent>
    </Card>
  );
};
```

### Infrastructure as Code

**Bicep Best Practices:**

```bicep
@description('The name of the resource')
param resourceName string

@description('The location for the resource')
param location string = resourceGroup().location

@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string

var tags = {
  Environment: environment
  ManagedBy: 'Bicep'
  Project: 'Healthcare-AI'
}

resource example 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceName
  location: location
  tags: tags
}
```

---

## Testing Requirements

### Test Coverage Requirements

- **Minimum Coverage**: 80%
- **Critical Paths**: 95%
- **Security Functions**: 100%

### Python Testing

```bash
# Run tests
pytest tests/ -v

# With coverage
pytest tests/ --cov=. --cov-report=html --cov-report=term

# Run specific test
pytest tests/test_fhir_integration.py::test_patient_search
```

**Example Test:**

```python
import pytest
from unittest.mock import Mock, patch
from agents.primary_care_agent import PrimaryCareAgent


@pytest.fixture
def mock_fhir_client():
    """Mock FHIR client for testing."""
    client = Mock()
    client.get_patient.return_value = {
        'id': 'patient-123',
        'name': [{'given': ['John'], 'family': 'Doe'}]
    }
    return client


def test_patient_assessment(mock_fhir_client):
    """Test patient assessment workflow."""
    agent = PrimaryCareAgent(fhir_client=mock_fhir_client)
    
    result = agent.assess_patient('patient-123')
    
    assert result is not None
    assert result['patient_id'] == 'patient-123'
    assert 'findings' in result
    mock_fhir_client.get_patient.assert_called_once_with('patient-123')
```

### React Testing

```bash
# Run tests
npm test

# With coverage
npm test -- --coverage --watchAll=false

# E2E tests
npm run test:e2e
```

**Example Test:**

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { PatientSearch } from './PatientSearch';

describe('PatientSearch', () => {
  it('should search for patients', async () => {
    const mockOnSelect = jest.fn();
    
    render(<PatientSearch onSelect={mockOnSelect} />);
    
    const searchInput = screen.getByPlaceholderText('Search patients...');
    fireEvent.change(searchInput, { target: { value: 'John Doe' } });
    
    const searchButton = screen.getByRole('button', { name: /search/i });
    fireEvent.click(searchButton);
    
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });
  });
});
```

### Integration Testing

```python
# tests/integration/test_end_to_end.py
def test_complete_assessment_workflow():
    """Test complete patient assessment workflow."""
    # 1. Search for patient
    patient = search_patient('John Doe')
    assert patient is not None
    
    # 2. Start assessment
    assessment = start_assessment(patient['id'], 'comprehensive')
    assert assessment['status'] == 'in_progress'
    
    # 3. Wait for completion
    result = wait_for_assessment(assessment['id'], timeout=300)
    assert result['status'] == 'completed'
    assert 'recommendations' in result
```

---

## Security Guidelines

### HIPAA Compliance

**All contributions MUST:**

1. ✅ Never log PHI (Protected Health Information)
2. ✅ Use encryption for data at rest and in transit
3. ✅ Implement proper access controls
4. ✅ Include audit logging
5. ✅ Follow least privilege principle

### Secure Coding Practices

**DO:**

```python
# ✅ Use parameterized queries
cursor.execute("SELECT * FROM patients WHERE id = %s", (patient_id,))

# ✅ Validate input
def validate_patient_id(patient_id: str) -> bool:
    return bool(re.match(r'^[a-zA-Z0-9-]+$', patient_id))

# ✅ Use secrets from Azure Key Vault
from azure.keyvault.secrets import SecretClient
secret = secret_client.get_secret("azure-openai-key")
```

**DON'T:**

```python
# ❌ Never commit secrets
OPENAI_API_KEY = "sk-abc123..."  # NEVER DO THIS

# ❌ Don't use string concatenation for SQL
query = f"SELECT * FROM patients WHERE id = '{patient_id}'"  # SQL INJECTION!

# ❌ Don't log sensitive data
logger.info(f"Processing patient: {patient_ssn}")  # PHI VIOLATION!
```

### Security Checklist

Before submitting a PR, verify:

- [ ] No hardcoded secrets or credentials
- [ ] No PHI in logs or error messages
- [ ] Input validation implemented
- [ ] SQL injection prevention
- [ ] XSS prevention (frontend)
- [ ] CSRF protection
- [ ] Proper error handling (no sensitive info in errors)
- [ ] Dependencies scanned for vulnerabilities

---

## Pull Request Process

### Before Submitting

1. **Update your branch**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout feature/your-feature
   git rebase develop
   ```

2. **Run all tests**:
   ```bash
   pytest tests/ --cov=.
   npm test -- --coverage
   ```

3. **Run linters**:
   ```bash
   black .
   flake8 .
   npm run lint
   ```

4. **Update documentation**:
   - Update README if needed
   - Add/update API documentation
   - Update CHANGELOG.md

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Security
- [ ] No PHI in logs
- [ ] No hardcoded secrets
- [ ] Security scan passed
- [ ] HIPAA compliance verified

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests pass locally
- [ ] No merge conflicts

## Related Issues
Closes #123
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs automatically
2. **Code Review**: At least 2 approvals required
3. **Security Review**: For security-related changes
4. **Compliance Review**: For HIPAA-related changes

### Merge Requirements

- ✅ All CI/CD checks pass
- ✅ Code coverage ≥ 80%
- ✅ No security vulnerabilities
- ✅ 2+ approvals
- ✅ Up to date with target branch

---

## Recognition

Contributors will be recognized in:

- CONTRIBUTORS.md file
- Release notes
- Project documentation

---

## Questions?

- **Technical Questions**: Open a GitHub Discussion
- **Security Issues**: Email security@healthcare-ai.com (do not open public issues)
- **General Questions**: Reach out on Microsoft Teams

---

**Thank you for contributing to healthcare innovation! 🏥💙**
