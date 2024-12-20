[Setup.Simulators]
Simulators.Name.ES=Simuladores

Simulators.MFDKeys.openPitstopMFD.ES=Abrir diálogo de Pitstop
Simulators.MFDKeys.closePitstopMFD.ES=Cerrar diálogo de Pitstop

Simulators.MFDKeys.togglePitstopFuelMFD.ES=Alternar combustible MFD
Simulators.MFDKeys.togglePitstopTyreMFD.ES=Alternar neumático MFD

Simulators.MFDKeys.previousOption.ES=Opción anterior
Simulators.MFDKeys.nextOption.ES=Siguiente opción
Simulators.MFDKeys.previousChoice.ES=Elección anterior
Simulators.MFDKeys.nextChoice.ES=Siguiente elección
Simulators.MFDKeys.acceptChoice.ES=Aceptar elección

Simulators.MFDKeys.requestPitstop.ES=Solicitar parada en boxes

Simulators.Title.ES=Ayuda y más información
Simulators.Subtitle.ES=Configuración del controlador para los simuladores...
Simulators.Info.ES=<i>Simulator Controller</i> proporciona diferentes modos para su controlador externo para la mayoría de los simuladores, con el que puede realizar varios ajustes en la simulación, por ejemplo, la información para un próximo Pitstop. También puedes comunicarte con los asistentes de carrera pulsando un botón, si no quieres utilizar la entrada de voz. Encontraras un resumen de las funciones de los asistentes <a href="https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes" target="_blank">aquí</a>.<br><br>En un paso anterior de este asistente de configuración, configuró su controlador y en este paso asigna las acciones disponibles a los elementos de control con los que desea activar la acción. Asegúrese de mantener juntas todas las acciones de un modo, para que se cree un grupo lógico. Si ha conectado y configurado varios controladores externos, más tarde puede tener un modo activo en cada dispositivo de entrada. Sin embargo, también es posible que un modo distribuya acciones entre varios controladores.<br><br>Recuerde que además de las acciones que están vinculadas a un modo se pueden cambiar dinámicamente y también hay acciones que están siempre activas. Un comando muy especial es la acción de selector de modo, con la que puedes cambiar entre los modos individuales y que ya configuraste en un paso anterior. Pero hay otras acciones para las que tiene sentido que estén siempre disponibles. Así que reserve algunos controles para estas acciones. Una asignación típica de una botonera puede ser así:<br><br><img src='%kResourcesDirectory%Setup\Images\Button Box Example.jpg' style='margin-left: auto' style='margin-right: auto'><br><br>Los botones de la fila superior siempre están asignados a sus acciones correspondientes y activan o desactivan la función de movimiento del Motion Rig o los motores de vibración individuales. El modo activo se puede seleccionar con el interruptor en la parte superior izquierda. Todos los botones de la zona inferior pertenecen al modo actualmente activo, en este caso el modo <i>Iniciar</i>, con el que puede iniciar y detener aplicaciones de Windows desde el controlador externo.<br><br><b>Importante:</b> Para los simuladores <i>Assetto Corsa Competizione</i> y <i>RaceRoom Racing Experience</i>, pueden ser necesarios pasos de configuración manual para respaldar las acciones de Pitstop. Estos se describen <a href="https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes#important-preparation-for-the-pitstop-mfd-handling" target="_blank">aquí</a> y <a href="https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes#important-preparation-for-the-pitstop-mfd-handling-1" target="_blank">aquí</a> Si desea utilizar <i>Assetto Corsa</i> y/o <i>rFactor 2</i>, debe instalar un complemento especial en el directorio de instalación de estos simuladores. Puede encontrar información sobre esto <a href="https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#installation-of-telemetry-providers" target="_blank">aquí</a>.<br><br>Y un último consejo: puede definir reglas para qué modo debe activarse automáticamente. Esto es particularmente útil durante una simulación en ejecución simulador en ejecución. Más información sobre esto <a href="https://github.com/SeriousOldMan/Simulator-Controller/wiki/Using-Simulator-Controller#configuration-of-the-controller-mode-automation" target="_blank">aquí</a>.

Simulators.Actions.Info.ES=Utilice el menú <i>Simulador</i> en la parte superior izquierda para seleccionar el simulador que desea configurar. La mayoría de los simuladores brindan un modo "Pitstop" con acciones con las que puede cambiar la configuración para la próxima parada en boxes desde un controlador externo. Si ha seleccionado al menos uno de los asistentes de carrera en el primer paso de este asistente de configuración, también se proporciona un modo de "asistente" con acciones que puede usar para comunicarse con los asistentes a través de un controlador externo. Para configurar las acciones, proceda de la siguiente manera:<br><br><ol><li>Haga clic en una acción para abrir el menú contextual y luego elija el elemento de menú "Establecer función" para ingresar al modo de asignación.</li><li>Luego, haga clic en un elemento de control en uno de los controladores que se muestran en el lado derecho de la pantalla. La acción se vincula entonces a este elemento de control. Tenga en cuenta que muchas acciones cambian un valor, por ejemplo, la cantidad de gasolina que se debe repostar. Por lo tanto, debe en estos casos, de forma similar a los pasos de configuración posteriores, elegir un control que también tenga <i>dos valores</i>, por ejemplo, un dial giratorio, o asigna dos controles <i>de un solo valor</i>.</li></ol>Algunas observaciones adicionales: También puede invertir el orden, es decir, primero seleccione el elemento de control y luego la acción, y tambien, puede usar el menú en la parte superior izquierda en uno de los controladores en el borde derecho de la pantalla para seleccionar el modo que se usa para la vista previa. Esto le ayuda a obtener una impresión de la disposición posterior al asignar las acciones a los elementos de control individuales. Y finalmente: el modo de vista previa es un poco limitada, es decir, solo los identificadores estáticos de las acciones individuales se muestran en la ventana de vista previa para identificarlas. Los íconos específicos de la acción (para Stream Deck) o los textos dinámicos solo serán visibles eal ejecutarse.