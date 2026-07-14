# terraform-eft-auy1105-grupo-6

**Evaluación Final Transversal — AUY1105 Infraestructura como Código II**
DuocUC — Escuela de Informática y Telecomunicaciones

---

## 1. Introducción

Este repositorio consolida el trabajo desarrollado durante el semestre en los Parciales 1, 2 y 3 de
AUY1105, integrando en una única solución de Infraestructura como Código (IaC) los tres pilares
evaluados: calidad y seguridad del código (RA1, RA2), modularidad reutilizable (RA3), y gestión
avanzada del estado de Terraform (RA4).

La solución despliega infraestructura de red y cómputo en AWS mediante módulos de Terraform
propios, publicados y versionados en el Terraform Registry, orquestados desde este repositorio
central mediante un pipeline de integración y despliegue continuo (CI/CD) que valida calidad,
seguridad y políticas antes de aplicar cualquier cambio en la nube.

## 2. Alcance

**Objetivos cumplidos:**
- Automatizar el ciclo completo de despliegue de infraestructura, desde la validación de código hasta el `apply` en AWS
- Reutilizar como módulos versionados el trabajo de los Parciales 2 y 3 (red, cómputo, almacenamiento de estado)
- Aplicar políticas de seguridad como código, con pruebas automatizadas que validan su efectividad
- Separar el ciclo de vida del backend de Terraform del ciclo de vida de la infraestructura de aplicación

**Recursos utilizados:**
- AWS Learner Lab (cuenta educativa con credenciales temporales)
- GitHub (repositorios + GitHub Actions + Terraform Registry)
- Open Policy Agent (OPA) para políticas de seguridad
- Checkov y TFLint para análisis estático

**Criterios de éxito:**
- El pipeline puede crear y destruir toda la infraestructura sin intervención manual, salvo la actualización periódica de credenciales temporales del Lab
- Las políticas de seguridad bloquean configuraciones inseguras de forma demostrable (con pruebas, no solo de palabra)
- Los módulos son reutilizables fuera de este proyecto, con documentación propia en el Registry

## 3. Diseño de la solución

La solución se organiza en 4 repositorios con responsabilidades separadas:

| Repositorio | Rol | Se publica en Registry |
|---|---|---|
| `terraform-aws-s3-auy1105-grupo-6` | Módulo reutilizable: bucket S3 seguro (versionado, cifrado, locking opcional) | ✅ Sí |
| `terraform-aws-vpc-AUY1105-grupo-6` | Módulo reutilizable: red completa (VPC, subnets, NAT, rutas) | ✅ Sí |
| `terraform-aws-ec2-AUY1105-grupo-6` | Módulo reutilizable: instancia EC2 con security group | ✅ Sí |
| `terraform-eft-auy1105-grupo-6` (este repo) | Orquestador: consume los 3 módulos, aplica políticas, corre el pipeline | ❌ No (no aplica) |

**Por qué esta separación:** cada módulo se desarrolla, versiona y prueba de forma independiente,
permitiendo que cualquier otro proyecto los reutilice sin depender de este repositorio. El repo
principal solo orquesta — no contiene lógica de infraestructura propia más allá de las políticas
de seguridad y la configuración del pipeline.

**Componentes dentro de este repositorio:**

| Carpeta/archivo | Función |
|---|---|
| `bootstrap/` | Configuración independiente que crea el bucket S3 + backend, usado antes de que exista el backend remoto |
| `policies/` | Políticas de seguridad en Rego (OPA) + sus pruebas unitarias |
| `docs/` | Documentación de decisiones técnicas y gestión de estado |
| `main.tf`, `variables.tf`, `outputs.tf` | Orquestación de los módulos de red y cómputo |
| `versions.tf`, `data.tf` | Provider de AWS y autodetección de AMI |
| `backend.tf` | Configuración parcial del backend (el bucket se inyecta en tiempo de ejecución) |
| `.github/workflows/` | Pipelines de CI/CD (principal y de bootstrap, separados) |

## 4. Diagrama de arquitectura

<img width="3218" height="1000" alt="arquitectura-pipeline-terraform-grupo6 (1)" src="https://github.com/user-attachments/assets/d700e62d-66b0-44b0-af3c-6592b17998d1" />

```
                    ┌─────────────────────────────┐
                    │   Terraform Registry         │
                    │  (s3 / vpc / ec2 - grupo-6)   │
                    └──────────────┬───────────────┘
                                   │ consumido por
                                   ▼
   ┌───────────────────────────────────────────────────────────┐
   │           terraform-eft-auy1105-grupo-6 (este repo)         │
   │                                                             │
   │   bootstrap/  ──crea──▶  Bucket S3 (backend de state)       │
   │        │                        ▲                          │
   │        │                        │ usado como backend por    │
   │        ▼                        │                          │
   │   main.tf  ──invoca──▶  módulo vpc  ──▶  módulo ec2          │
   │        │                                                    │
   │        ▼                                                    │
   │   policies/*.rego  ──valida──▶  plan de Terraform            │
   └───────────────────────────────────────────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────┐
                    │   .github/workflows/          │
                    │   bootstrap.yml (manual)       │
                    │   ci-cd.yml (push / manual)    │
                    └──────────────┬───────────────┘
                                   │ despliega en
                                   ▼
                    ┌─────────────────────────────┐
                    │   AWS (Learner Lab)            │
                    │   VPC + Subnets + NAT + EC2     │
                    └─────────────────────────────┘
```

## 5. Cómo desplegar todo desde cero

### Requisito previo: credenciales y variables configuradas

En `Settings → Secrets and variables → Actions` de este repositorio:

| Tipo | Nombre | Contenido |
|---|---|---|
| Secret | `AWS_ACCESS_KEY_ID` | De AWS Learner Lab → AWS Details |
| Secret | `AWS_SECRET_ACCESS_KEY` | De AWS Learner Lab → AWS Details |
| Secret | `AWS_SESSION_TOKEN` | De AWS Learner Lab → AWS Details |
| Variable | `TF_STATE_BUCKET` | Nombre del bucket de state (ver sección 9) |

⚠️ Las credenciales de Learner Lab expiran cada pocas horas. Si el pipeline falla con
`No valid credential sources found`, actualiza los 3 Secrets con la sesión activa del Lab.

### Paso 1 — Crear el backend (una sola vez, o si se perdió el bucket)

`Actions → Bootstrap State Backend → Run workflow → apply`

Es idempotente: si el bucket ya existe, no hace nada y lo informa en el log.

### Paso 2 — Crear la infraestructura completa

`Actions → CI/CD EFT → Run workflow → apply`

Ejecuta en orden: `terraform fmt/validate` → `tflint` → Checkov → pruebas OPA → `terraform apply`.
Si cualquier verificación falla, el `apply` no se ejecuta.

### Paso 3 — Verificar en AWS

- **EC2 → Instances**: debe aparecer `eft-instancia-grupo-6` en estado *running*
- **VPC → Your VPCs**: debe aparecer `eft-vpc-grupo-6`

### Paso 4 — Destruir la infraestructura

`Actions → CI/CD EFT → Run workflow → destroy`

### Paso 5 — (Opcional) Destruir también el backend

`Actions → Bootstrap State Backend → Run workflow → destroy`

Solo al final del ciclo completo — nunca antes del Paso 4, porque el backend
contiene el state necesario para destruir la infraestructura correctamente.

## 6. Módulos del Terraform Registry

Cada módulo puede usarse de forma independiente en cualquier otro proyecto Terraform:

### `s3` — bucket seguro con locking opcional

```hcl
module "storage" {
  source  = "Infra-como-codigo-II-2026/s3-auy1105-grupo-6/aws"
  version = "~> 1.1.2"

  project            = "mi-proyecto"
  environment        = "dev"
  bucket_suffix      = "data"
  versioning_enabled = true
  create_lock_table  = false
}
```

### `vpc` — red completa

```hcl
module "networking" {
  source  = "Infra-como-codigo-II-2026/vpc-AUY1105-grupo-6/aws"
  version = "~> 1.0.1"

  vpc_name    = "mi-vpc"
  vpc_cidr    = "10.0.0.0/16"
  project     = "mi-proyecto"
  environment = "dev"
}
```

### `ec2` — instancia con security group

```hcl
module "compute" {
  source  = "Infra-como-codigo-II-2026/ec2-AUY1105-grupo-6/aws"
  version = "~> 1.0.1"

  key_name      = "vockey"
  ami           = "ami-xxxxxxxxxxxxxxxxx"
  subnet_id     = module.networking.subnet_publica_1_id
  vpc_id        = module.networking.vpc_id
  instance_name = "mi-instancia"
  project       = "mi-proyecto"
  environment   = "dev"
}
```

Documentación detallada de variables y outputs de cada uno, en su página del Registry (ver Anexos).

## 7. Políticas de seguridad

Escritas en Rego (sintaxis Rego v1), evaluadas automáticamente en el pipeline con OPA:

| Política | Qué bloquea |
|---|---|
| `policies/s3_public_access.rego` | Buckets S3 con `block_public_acls` en `false` |
| `policies/ssh_open_ports.rego` | Puertos abiertos a `0.0.0.0/0` distintos del 22 (SSH permitido solo por requisito de Learner Lab, documentado en el código) |

Cada política tiene su archivo `_test.rego` correspondiente, con casos que deben ser
rechazados y casos que deben ser aceptados — ejecutados en el pipeline vía `opa test policies/ -v`.

## 8. Pipeline CI/CD

Dos workflows independientes, con ciclos de vida distintos:

**`bootstrap.yml`** — manual (`workflow_dispatch`), crea o destruye el bucket de state.
Idempotente: verifica con `aws s3api head-bucket` antes de actuar.

**`ci-cd.yml`** — automático en cada `push`/`pull_request`, y también disponible manualmente
para `apply`/`destroy` bajo demanda:

```
Terraform Checks (fmt, validate, tflint)
        │
Checkov Security Analysis
        │
OPA Policy Tests
        │
Terraform Apply / Destroy
```

## 9. Gestión del estado y nombre del bucket

El bucket de backend se nombra `{project}-{environment}-{bucket_suffix}` dentro de
`bootstrap/main.tf`. Como los nombres de bucket S3 son únicos a nivel global (entre todas
las cuentas de AWS del mundo, no solo la tuya), el `bucket_suffix` incluye un sufijo aleatorio
para evitar colisiones — especialmente relevante en AWS Learner Lab, donde las cuentas son
compartidas dentro de un pool educativo.

La Variable `TF_STATE_BUCKET` en GitHub debe coincidir siempre con el nombre resultante de esa
fórmula. Ver `docs/gestion-de-estado.md` para el detalle de comandos avanzados de Terraform CLI
aplicados durante el desarrollo (`state mv`, `import`, `refresh`, `taint`).

## 10. Conclusiones

La solución consolidada aborda de manera integral los desafíos identificados en los tres
parciales: se automatizó completamente el ciclo de vida de la infraestructura (calidad,
seguridad, modularidad y gestión de estado), reduciendo la intervención manual a la
actualización periódica de credenciales temporales del entorno educativo. La separación entre
backend y aplicación, junto con políticas de seguridad probadas automáticamente, refleja
una arquitectura alineada con prácticas reales de DevSecOps, cumpliendo con los requisitos
técnicos especificados en los Parciales 1, 2 y 3 y sus objetivos de aprendizaje asociados.

## 11. Anexos

- **GitHub Repository:** https://github.com/Infra-como-codigo-II-2026/terraform-eft-auy1105-grupo-6
- **Terraform Registry — módulo S3:** https://registry.terraform.io/modules/Infra-como-codigo-II-2026/s3-auy1105-grupo-6/aws
  <img width="1415" height="711" alt="image" src="https://github.com/user-attachments/assets/69d06dcb-2e72-4dc5-af9e-bb62a9079991" />

- **Terraform Registry — módulo VPC:** https://registry.terraform.io/modules/Infra-como-codigo-II-2026/vpc-AUY1105-grupo-6/aws
  <img width="1409" height="571" alt="image" src="https://github.com/user-attachments/assets/7952a52d-0e7b-4534-9078-741aa32165e6" />

- **Terraform Registry — módulo EC2:** https://registry.terraform.io/modules/Infra-como-codigo-II-2026/ec2-AUY1105-grupo-6/aws
 <img width="1426" height="598" alt="image" src="https://github.com/user-attachments/assets/44e4735d-9d8a-4eaa-9248-8ec7eed971e9" />


## 12. Mapeo de Indicadores de Logro

| IL | Evidencia en este repositorio |
|---|---|
| IL1.1 | `.github/pull_request_template.md` — fuerza documentar sugerencias y errores en cada PR |
| IL1.2 | `.github/workflows/checkov.yml` + `terraform.yml` (fmt, validate, tflint) |
| IL1.3 | Este README + `readme.md`/`CHANGELOG.md` de cada módulo |
| IL2.1 | `policies/*.rego` |
| IL2.2 | Job `policy-tests` en `ci-cd.yml`, bloquea el `apply` si las políticas fallan |
| IL2.3 | `policies/*_test.rego` — pruebas automatizadas con casos positivos y negativos |
| IL3.1 | Los 3 módulos publicados, estructurados con `main.tf`/`variables.tf`/`outputs.tf` |
| IL3.2 | `README.md` de cada módulo, con tablas de variables y outputs |
| IL3.3 | Tags semver (`v1.0.0`, `v1.1.0`, etc.) y `CHANGELOG.md` de cada módulo |
| IL4.2 | `data.tf` (autodetección de AMI), separación backend/infraestructura, locking configurable |

## Dependencias

- Terraform >= 1.3.0
- AWS Provider ~> 5.0
- Cuenta AWS Learner Lab activa
- Open Policy Agent (`opa`) para evaluar políticas localmente
- Checkov y TFLint (instalados automáticamente en el pipeline)
