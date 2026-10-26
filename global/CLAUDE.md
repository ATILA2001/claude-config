# Reglas globales (todos los proyectos)

## Git y control de versiones
- Nunca crear commits, ramas ni hacer push sin que el usuario lo solicite o lo autorice explícitamente. Nunca hacer push directo a main.
- Antes de un commit, mostrar los archivos afectados y proponer el mensaje.
- No incluir Co-Authored-By, "Generated with Claude Code" ni menciones a herramientas de IA en commits ni en pull requests.
- No modificar ni descartar cambios preexistentes sin autorización (incluye reset, restore, checkout, clean, rebase y merge).

## Desarrollo
- Priorizar cambios mínimos, claros y mantenibles.
- Respetar la arquitectura y las convenciones existentes en cada proyecto.
- No realizar refactorizaciones fuera del alcance solicitado.
- No instalar ni actualizar dependencias sin autorización.
- No usar paquetes preview, beta ni release candidate.
- Agregar o actualizar pruebas para cada comportamiento relevante.
- Al terminar, informar qué archivos se modificaron y qué verificaciones se realizaron.
- No afirmar que una solución fue probada si no se ejecutaron las pruebas.

## Seguridad y alcance
- Trabajar solo dentro del repositorio abierto. No escribir fuera de él salvo pedido explícito del usuario.
- No modificar sistema ni infraestructura: IIS, servicios, registro, firewall, DNS, certificados, SPN, usuarios, grupos, permisos NTFS ni runners.
- No ejecutar despliegues.
- No modificar .github/workflows ni otros pipelines de CI/CD sin autorización.
- No solicitar, mostrar ni almacenar contraseñas, tokens, certificados ni cadenas de conexión reales.
- No incluir secretos en Git, logs, argumentos de comandos, capturas ni artifacts.
