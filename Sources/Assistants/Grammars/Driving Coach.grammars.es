// Standard
#Include Choices.es
#Include Conversation.es
[Configuration]
Recognizer=Mixed
[Fragments]
SessionInformation=Información de la sesión
StintInformation=Información de la Stint
HandlingInformation=Información de comportamiento de conducción
Fastest=rápida
Last=última
[Choices]
Announcements=Información de la sesión, Información de la Stint, Información de comportamiento de conducción
[Listener Grammars]
// Conversation //
AnnouncementsOff=[{Tenga en cuenta, Aviso} (Announcements) no más, {Por favor ignorar, Ignorar} (Announcements), Ignorar (Announcements) por favor]
AnnouncementsOn=[{Nota, Tome en cuenta, Tome en cuenta, Tome en cuenta} (Anuncios) nuevamente, {Otra vez tome en cuenta, Tome en cuenta nuevamente, Tome en cuenta nuevamente, Tome en cuenta nuevamente} (Anuncios)]
// Coaching //
CoachingStart=[(CanYou) darme una {entrenamiento, lección de entrenamiento}, (CanWe) realizar una sesión de {entrenamiento, entrenamiento, práctica, práctica}, (CanYou) {ayudarme, ayudarme} con {el, mi} {entrenamiento, práctica, practicar}, (CanYou) {observar, observar} mi {entrenamiento, practicar, practicar, conducir}, (CanYou) {revisar, observar} mi conducción {técnica, estilo}, (CanWe) mejorar mis habilidades de conducción]
CoachingFinish=[Gracias {por tu ayuda, aprendí mucho, estuvo genial}, estuvo genial, gracias, está bien, es suficiente por hoy]
ReviewLap=[(CanYou) darme {una descripción general, una descripción general esquina por esquina, una descripción general de toda la vuelta, una descripción general completa, una descripción general completa esquina por esquina}, {Por favor echa, Echa} un vistazo a la pista completa, ¿Dónde puedo mejorar en la pista]
ReviewCorner=[(CanWe) {centrarnos, hablar sobre} {número de esquina, esquina} (Number), {Por favor toma, Toma} {mira más de cerca, mira} a {número de esquina, esquina} (Number), ¿Dónde puedo mejorar? {número de esquina, esquina} (Number), ¿Qué debo considerar {para, en} {número de esquina, esquina} (Number)]
TrackCoachingStart=[(CanYou) darme {recomendaciones, consejos, una guía, instrucciones} {mientras conduzco, para cada curva}, {Por favor dime, Dime} {antes de, para} cada curva lo que {puedo, debería} cambiar, (CanYou) entrenarme {en la pista, mientras conduzco}]
TrackCoachingFinish=[{Gracias ahora, Ahora} quiero concentrarme, {Está bien déjame, Déjame} {aplicar, probar} {tus recomendaciones, tus instrucciones, eso} ahora, {Por favor deja, Deja} dándome {recomendaciones, consejos, instrucciones, recomendaciones para cada rincón, tips para cada rincón, instrucciones para cada rincón}, {Por favor no, No} más {instrucciones, instrucciones por favor}]
ReferenceLap=[(CanWe) usar la vuelta {más rápida, última} como {referencia, vuelta de referencia}, {Por favor use, Use} la vuelta {más rápida, última} como {referencia, vuelta de referencia}]
NoReferenceLap=[{Por favor haz, Haz} no utilices una referencia {vuelta, vuelta por favor}]
// Conversation //
Later.1=Lo siento, estoy ocupado ahora mismo. Por favor contáctame más tarde.
Later.2=Actualmente estoy en la otra línea. Dame algo de tiempo.
Later.3=Sólo tengo que evaluar algunos datos. Ponte en contacto nuevamente en 5 minutos.
// Announcement Handling //
ConfirmAnnouncementOff.1=Ya no quieres hablar más sobre %announcement%, ¿verdad?
ConfirmAnnouncementOff.2=Voy a ignorar %announcement% por ahora, ¿verdad?
ConfirmAnnouncementOn.1=Quieres que preste atención a %announcement% nuevamente, ¿verdad?
ConfirmAnnouncementOn.2=Prestaré atención a %announcement% nuevamente, ¿es correcto?
// Coaching //
ConfirmCoaching.1=Por supuesto. Corro ya algunas vueltas hasta que haya encendido mi computadora. Volveré contigo cuando vea los datos de telemetría.
ConfirmCoaching.2=Sí, claro. Arrancaré mi computadora y ya corres algunas vueltas. Me pondré en contacto contigo cuando esté listo.
CoachingReady.1=Aquí está %name%, estoy listo. ¿Dónde necesitas mi ayuda?
CoachingReady.2=%name% aquí. Están llegando datos. ¿Qué puedo hacer por usted?