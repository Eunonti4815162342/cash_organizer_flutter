# Mandatos del Experto en UI/UX y Arquitectura Flutter

Este proyecto tiene como objetivo la recreación de alta fidelidad de la aplicación "Cash Organizer" original. Como experto en diseño y arquitectura, dictamino las siguientes directrices obligatorias:

## 🏗️ Arquitectura y Principios de Ingeniería
- **Arquitectura Hexagonal (Puertos y Adaptadores):** El núcleo de la aplicación (Domain) debe estar aislado de los detalles de infraestructura (APIs, Local Storage).
- **Domain-Driven Design (DDD):** El desarrollo se centrará en el lenguaje ubicuo del dominio financiero (Accounts, Transactions, Budgets) extraído del análisis de la APK.
- **Principios SOLID:** Cada widget y servicio debe cumplir con una única responsabilidad (SRP), ser extensible sin modificar (OCP) y depender de abstracciones (DIP).

## 🎨 Identidad Visual y Estilo
- **Paleta de Colores Crítica:** 
  - Primario: `#009FFB` (Azul oficial).
  - Texto/Iconos Secundarios: `#4A636F` (Gris oscuro/Petróleo).
  - Fondo de Ventana: `#F5F5F5` (Gris muy claro).
- **Recursos:** Los iconos deben ser extraídos gradualmente de la carpeta `res/drawable` del proyecto descompilado para sustituir los iconos de Material genéricos cuando sea posible.

## 📱 Estructura de Navegación
- **Navegación:** Se debe mantener la estructura de `DrawerLayout` analizada en el XML original.
- **Componentización:** Cada elemento visual (tarjetas, botones, menús) debe ser un widget independiente para facilitar ajustes finos de diseño.

## 📈 Estado Actual del Proyecto
1. **Identidad Visual:** Aplicados azul oficial (`#009FFB`) y grises oscuros (`#4A636F`).
2. **Estructura del Esqueleto:** Recreación de `DrawerLayout`, `AppBar` profesional, `FloatingActionButton` circular y Menú lateral con banner "Go Premium".
3. **Tarjetas de Cuentas:** Rediseño estético con sombras y tipografía avanzada.

## 🚀 Próximos Pasos (Prioridad Alta)
1. **Extracción de Iconos:** Localizar y convertir archivos `.png` o `.xml` de `res/drawable` para su uso en Flutter.
2. **Pantalla de Transacciones:** Construcción de la vista detallada de movimientos financieros, imitando la lista original.
3. **Refactorización a Capas:** Ajustar la estructura de carpetas de Flutter para reflejar la Arquitectura Hexagonal (Domain, Application, Infrastructure).
