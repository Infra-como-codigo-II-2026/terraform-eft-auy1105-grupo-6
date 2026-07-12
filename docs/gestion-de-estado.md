# Gestion del estado - comandos avanzados aplicados

Este documento registra los comandos de Terraform CLI usados durante la consolidacion
de la EFT para gestionar el estado de forma segura, mas alla de lo evaluado directamente
en la pauta (que solo considera IL4.2), como evidencia de la aplicacion integral de RA4.

## Comandos utilizados

| Comando | Cuando se uso | Proposito |
|---|---|---|
| `terraform state list` | Antes de consolidar los parciales | Verificar que recursos existian en cada state por separado |
| `terraform state mv` | Al migrar recursos al repo consolidado | Reasignar recursos a la nueva estructura de modulos sin destruir/recrear |
| `terraform import` | Al detectar recursos creados manualmente | Traer bajo control de Terraform recursos que ya existian en AWS |
| `terraform refresh` | Antes de cada apply | Detectar drift entre el state y la infraestructura real |
| `terraform taint` | Al forzar recreacion de un recurso con configuracion corrupta | Marcar recursos para recreacion en el proximo apply |

## Optimizacion aplicada (IL4.2)

- Uso de data source `aws_ami` para autodetectar la AMI en vez de hardcodearla
- Separacion de backend remoto del codigo de infraestructura (carpeta bootstrap/ aislada)
- Locking explicito via DynamoDB para evitar aplicaciones concurrentes corruptas
- Modulos consumidos por version fija desde el Registry, evitando cambios inesperados