// lib/legal_content.dart
// Texto de los Términos de uso y de la Política de Privacidad de Syklist.
// Cuando cambies cualquiera de los dos textos, subí la versión (versionTerminos):
// así queda registrado con qué versión se registró cada persona.

const String versionTerminos = '1.1';
const String fechaTerminos = 'noviembre de 2026';

// ↓↓↓ COMPLETAR con los datos reales del proyecto antes de entregar ↓↓↓
const String contactoLegal = 'tu-correo@ejemplo.com';
const String responsableLegal = 'el equipo del proyecto Syklist';

class SeccionLegal {
  final String titulo;

  /// Cada elemento es un párrafo. Los que empiezan con "• " se muestran como lista.
  final List<String> parrafos;

  const SeccionLegal(this.titulo, this.parrafos);
}

// ============================================================================
// TÉRMINOS DE USO
// ============================================================================
const List<SeccionLegal> terminosDeUso = [
  SeccionLegal('1. Aceptación de los términos', [
    'Al crear una cuenta o usar Syklist aceptás estos Términos de uso. Si no estás de acuerdo con ellos, no uses la aplicación.',
    'Syklist se encuentra en una versión de demostración, desarrollada con fines académicos. Algunas funciones pueden estar incompletas o cambiar sin aviso.',
  ]),
  SeccionLegal('2. Qué es Syklist', [
    'Syklist es una aplicación para ciclistas que ayuda durante sus trayectos con funciones de monitoreo, localización y seguridad. Con ella podés:',
    '• registrar tus recorridos usando el GPS de tu dispositivo;',
    '• ver tu ruta en un mapa, con la distancia y el tiempo;',
    '• consultar tu historial y tus estadísticas;',
    '• planificar una ruta hasta un destino.',
    'Está previsto sumar la detección de posibles caídas y las notificaciones de alerta.',
  ]),
  SeccionLegal('3. Tu cuenta', [
    'Para usar la aplicación necesitás una cuenta con un email y una contraseña. Tenés que dar datos verdaderos y mantenerlos actualizados.',
    'Sos responsable de cuidar tu contraseña y de lo que se haga con tu cuenta. Si creés que alguien la usa sin tu permiso, avisanos.',
    'Tenés que tener al menos 18 años, o contar con la autorización de tu madre, padre o tutor.',
  ]),
  SeccionLegal('4. Uso permitido', [
    'Te pedimos que uses Syklist de forma responsable. No está permitido:',
    '• usar la aplicación de una manera que ponga en riesgo tu seguridad o la de otras personas, por ejemplo mirar o manipular el teléfono mientras pedaleás;',
    '• intentar acceder a datos o cuentas de otras personas;',
    '• alterar, atacar o sobrecargar el servicio o sus sistemas;',
    '• usar la aplicación para actividades ilegales.',
  ]),
  SeccionLegal('5. Seguridad y responsabilidad', [
    'Syklist es una ayuda y no reemplaza tu atención ni tu criterio. Pedaleá siempre respetando las normas de tránsito.',
    'El GPS y los sensores de un teléfono pueden fallar o ser imprecisos. La distancia, el tiempo y la ruta que muestra la aplicación son aproximados.',
    'Cuando la detección de caídas esté disponible, puede no detectar una caída real o generar alertas falsas. No la uses como único medio de seguridad. En una emergencia, llamá a los servicios de emergencia de tu zona.',
  ]),
  SeccionLegal('6. Planes Gratis y Premium', [
    '• Plan Gratis: registro de recorridos, mapa y ruta en vivo, historial de tus últimos 5 recorridos y publicidad.',
    '• Plan Premium: historial ilimitado, estadísticas avanzadas y sin publicidad.',
    'En esta versión de demostración el pago es simulado: no se realiza ningún cobro real ni se pide ningún dato de pago. Los precios y las condiciones pueden cambiar; si eso pasa, te avisaremos en la aplicación.',
    'Podés volver al plan Gratis cuando quieras.',
  ]),
  SeccionLegal('7. Tus datos y tus recorridos', [
    'Tus recorridos y tus datos son tuyos. Nos das permiso para guardarlos y procesarlos únicamente para ofrecerte el servicio, tal como explica la Política de Privacidad.',
    'No vendemos tus datos.',
  ]),
  SeccionLegal('8. Propiedad intelectual', [
    'La aplicación, su diseño, su nombre y su código pertenecen a sus autores. No podés copiarlos ni usarlos como si fueran tuyos sin permiso.',
    'Los mapas son © colaboradores de OpenStreetMap.',
  ]),
  SeccionLegal('9. Disponibilidad del servicio', [
    'Ofrecemos Syklist “tal como está”. Puede haber interrupciones, errores o cambios, y podemos modificar o suspender funciones.',
    'En la medida que lo permita la ley, no somos responsables por los daños que resulten de usar la aplicación, de fallas del GPS o de la conexión, ni de la pérdida de datos.',
  ]),
  SeccionLegal('10. Cancelar o eliminar tu cuenta', [
    'Podés dejar de usar Syklist cuando quieras y pedir que eliminemos tu cuenta y tus datos escribiendo a $contactoLegal.',
    'Podemos suspender o cerrar las cuentas que incumplan estos términos.',
  ]),
  SeccionLegal('11. Cambios en estos términos', [
    'Podemos actualizar estos términos. Si hay cambios importantes, te lo avisaremos en la aplicación. Si seguís usando Syklist después del aviso, entendemos que aceptás la nueva versión.',
  ]),
  SeccionLegal('12. Ley aplicable y contacto', [
    'Estos términos se rigen por la ley aplicable en el país del responsable del servicio.',
    'Para cualquier consulta, escribinos a $contactoLegal.',
  ]),
];

// ============================================================================
// POLÍTICA DE PRIVACIDAD
// ============================================================================
const List<SeccionLegal> politicaDePrivacidad = [
  SeccionLegal('En pocas palabras', [
    '• Usamos tu ubicación solo para registrar tus recorridos y mostrarte la ruta.',
    '• Guardamos tu nombre, tu email y la actividad que registrás.',
    '• No vendemos tus datos ni los compartimos con anunciantes.',
    '• Podés pedir ver, corregir o borrar tus datos cuando quieras.',
    'Abajo está el detalle completo.',
  ]),
  SeccionLegal('1. Quién es responsable', [
    'El responsable del tratamiento de tus datos es $responsableLegal. Esta política explica qué datos recopilamos en Syklist, para qué los usamos, con quién los compartimos y cuáles son tus derechos.',
  ]),
  SeccionLegal('2. Qué datos recopilamos', [
    '• Datos de la cuenta: tu nombre, tu email y tu contraseña. La contraseña se guarda cifrada por nuestro proveedor de autenticación; nosotros no podemos verla.',
    '• Ubicación: cuando grabás un recorrido, la aplicación lee tu ubicación GPS (latitud, longitud y hora) y la guarda como puntos de la ruta. También se usa tu ubicación actual cuando tocás “Mi ubicación” o planificás una ruta.',
    '• Datos de actividad: el título, la fecha y la hora de inicio y fin, la distancia y la duración de cada recorrido, y las estadísticas que se calculan a partir de ellos.',
    '• Alertas de seguridad: si usás las alertas (por ejemplo, una posible caída), guardamos la fecha, la hora, la ubicación y el estado de la alerta.',
    '• Plan: si tu plan es Gratis o Premium.',
    '• Datos técnicos: un código de sesión que se guarda en tu dispositivo para mantenerte conectado y, si activás las notificaciones, un identificador de tu dispositivo para enviártelas.',
    'Solo leemos tu ubicación mientras grabás un recorrido o usás las funciones que la necesitan. En la aplicación para Android e iOS, mientras grabás un recorrido, la ubicación se sigue registrando aunque minimices la aplicación o bloquees la pantalla, y verás un aviso visible (una notificación en Android o un indicador en iOS). Cuando finalizás el recorrido, se deja de registrar. En el navegador, el registro se pausa si bloqueás la pantalla.',
  ]),
  SeccionLegal('3. Sensores del dispositivo', [
    'Cuando esté disponible la detección de caídas, la aplicación leerá el acelerómetro de tu dispositivo para identificar movimientos bruscos. Esa lectura sirve para decidir si hubo una posible caída y solo se guarda la alerta que resulte de ella.',
    'Tu dispositivo te pedirá permiso antes de usar la ubicación. Podés quitarlo cuando quieras desde los ajustes.',
  ]),
  SeccionLegal('4. Para qué usamos tus datos', [
    '• crear y mantener tu cuenta;',
    '• registrar tus recorridos y mostrarte tu ruta, tu historial y tus estadísticas;',
    '• aplicar los límites y los beneficios de tu plan;',
    '• mostrar publicidad en el plan Gratis. En esta versión los anuncios son de ejemplo y no usan tu ubicación ni tus recorridos;',
    '• mantener la seguridad del servicio y mejorarlo.',
  ]),
  SeccionLegal('5. Tu consentimiento', [
    'Tratamos tus datos con tu consentimiento, que nos das al marcar la casilla de aceptación al crear tu cuenta, y porque los necesitamos para prestarte el servicio. Guardamos qué versión de estos textos aceptaste y en qué fecha.',
    'Podés retirar tu consentimiento en cualquier momento pidiendo que eliminemos tu cuenta. Si lo hacés, no podremos seguir prestándote el servicio.',
  ]),
  SeccionLegal('6. Con quién compartimos tus datos', [
    'No vendemos tus datos. Para que la aplicación funcione usamos estos servicios de terceros:',
    '• Supabase: guarda la base de datos y se ocupa de la autenticación.',
    '• Vercel: aloja la API y el sitio web de la aplicación.',
    '• OpenStreetMap: al mostrar el mapa, tu dispositivo pide las imágenes a sus servidores, que reciben tu dirección IP y la zona que estás viendo.',
    '• Servicio público de rutas (OSRM): al calcular una ruta se envían las coordenadas de origen y de destino.',
    'Estos proveedores pueden guardar datos en servidores ubicados fuera de tu país. También podemos compartir datos si una ley o una autoridad competente lo exige.',
  ]),
  SeccionLegal('7. Cuánto tiempo guardamos tus datos', [
    'Guardamos tus datos mientras tu cuenta esté activa. Si la eliminás, borramos tus datos personales y tus recorridos, salvo lo que la ley nos obligue a conservar y las copias de seguridad, que se eliminan en un plazo razonable.',
  ]),
  SeccionLegal('8. Tus derechos', [
    'Podés pedirnos en cualquier momento:',
    '• acceder a tus datos y recibir una copia;',
    '• corregir los que sean incorrectos;',
    '• eliminar tu cuenta y tus datos;',
    '• oponerte a un uso o limitarlo;',
    '• retirar tu consentimiento.',
    'Escribinos a $contactoLegal y te respondemos en un plazo razonable.',
  ]),
  SeccionLegal('9. Cómo protegemos tus datos', [
    '• La conexión entre la aplicación y el servidor es cifrada (HTTPS).',
    '• Las contraseñas se guardan cifradas.',
    '• Cada persona solo puede ver y modificar sus propios datos.',
    '• Las claves de acceso a la base de datos están solo en el servidor, nunca dentro de la aplicación.',
    'Ningún sistema es completamente seguro, pero trabajamos para reducir los riesgos.',
  ]),
  SeccionLegal('10. Menores de edad', [
    'Syklist no está dirigida a menores de 18 años sin la autorización de su madre, padre o tutor. Si sabemos que tenemos datos de una persona menor sin esa autorización, los eliminaremos.',
  ]),
  SeccionLegal('11. Cambios en esta política', [
    'Podemos actualizar esta política. Si hay cambios importantes, te lo avisaremos en la aplicación y, cuando corresponda, volveremos a pedir tu consentimiento.',
  ]),
  SeccionLegal('12. Contacto', [
    'Para consultas o para ejercer tus derechos, escribinos a $contactoLegal.',
  ]),
];