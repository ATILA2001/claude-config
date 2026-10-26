# Reglas de este repositorio (.NET Framework 4.8)

## Stack y operaciones permitidas
- Proyecto en .NET Framework 4.8. Usar Git, PowerShell y MSBuild (Visual Studio Build Tools).
- Se permite restaurar paquetes (nuget restore o msbuild -t:restore), compilar con msbuild y ejecutar las pruebas con la herramienta que ya use el proyecto, siempre dentro del repositorio.
- No migrar a .NET moderno ni cambiar el TargetFramework sin autorización.
- No agregar ni actualizar paquetes NuGet a versiones que no sean compatibles con .NET Framework 4.8.

## Restricciones adicionales
- No incorporar Node.js, npm, Docker ni servicios externos sin autorización del responsable técnico.
- Crear ramas, commits o interactuar con remotos solo con autorización explícita del responsable técnico.
