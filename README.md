# terraform-eft-auy1105-grupo-6

Repositorio principal de la Evaluación Final Transversal (EFT) — AUY1105 Infraestructura como Código II.

Este repo orquesta la infraestructura completa consolidando el trabajo de los Parciales 1, 2 y 3:
red (VPC), cómputo (EC2) y almacenamiento de estado (S3), todo consumido como módulos versionados
desde el Terraform Registry, con políticas de seguridad automatizadas y despliegue vía pipeline CI/CD.

## Arquitectura

```
bootstrap/         → crea el bucket S3 + tabla DynamoDB para el backend remoto (uso único)
policies/           → políticas de seguridad en Rego + tests automatizados, evaluadas en el pipeline
docs/               → documentación de decisiones técnicas y gestión de estado
main.tf             → orquesta los módulos de red y cómputo desde el Registry
backend.tf          → apunta al bucket creado por bootstrap/
versions.tf         → provider y constraints de Terraform
data.tf             → autodetección de AMI
.github/workflows/  → pipeline CI/CD: terraform checks → checkov → policy tests → apply
```

## Módulos consumidos (Terraform Registry)

| Módulo | Registry | Uso |
|---|---|---|
| S3 (backend de estado) | `Infra-como-codigo-II-2026/s3-auy1105-grupo-6/aws` | Solo en `bootstrap/` |
| VPC (red) | `Infra-como-codigo-II-2026/vpc-auy1105-grupo-6/aws` | En `main.tf` |
| EC2 (cómputo) | `Infra-como-codigo-II-2026/ec2-auy1105-grupo-6/aws` | En `main.tf` |

## Cómo desplegar

### 1. Bootstrap (una sola vez, backend local)

```bash
cd bootstrap
terraform init
terraform apply
```

Anota los outputs `state_bucket_name` y `lock_table_name` — van en `backend.tf` de la raíz.

### 2. Infraestructura principal (backend remoto)

```bash
cd ..
terraform init
terraform plan
terraform apply
```

## Políticas de seguridad

Evaluadas automáticamente en el pipeline con Open Policy Agent, con tests unitarios propios:

- `policies/s3_public_access.rego` — bloquea que el bucket S3 permita acceso público
- `policies/ssh_open_ports.rego` — bloquea puertos abiertos a `0.0.0.0/0` salvo el 22 (SSH), justificado para acceso en AWS Learner Lab
- Cada política tiene su archivo `_test.rego` correspondiente, ejecutado en el pipeline vía `opa test`

## Pipeline CI/CD

Cada push o PR ejecuta, en orden: `terraform fmt` + `validate` + `tflint` → Checkov → pruebas de políticas OPA → `terraform apply` (solo en `main`, y solo si todo lo anterior pasa).

## Dependencias

- Terraform >= 1.3.0
- AWS Provider ~> 5.0
- Cuenta AWS Learner Lab activa
- Open Policy Agent (`opa`) para evaluar políticas localmente