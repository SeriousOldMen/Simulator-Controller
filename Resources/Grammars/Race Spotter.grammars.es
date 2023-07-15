[Fragments]
GreetingDry=está seco
GreetingDry2Wet=todavía está seco
GreetingWet=está mojado
GreetingWet2Dry=todavía está mojado
Faster=más rápido
Slower=más lento
Laps=vueltas
Lap=vuelta
Car=Coche
Position=Posición
DeltaInformation=Información delta
CutWarnings=avisos de atajo
PenaltyInformation=Información de penalización
Class=En nuestra clase
Overall=En general
TacticalAdvices=consejos tácticos
SideProximity=alertas laterales
RearProximity=alertas traseras
BlueFlags=avisos de bandera azul
YellowFlags=avisos de bandera amarilla
Sectors=primero,segundo,tercero,cuarto,quinto
Celsius=Celsius
Fahrenheit=Fahrenheit
Point=Punto
Comma=Coma
Number=Número
DT=servicio al carro
SG=detente y sigue
Time=tiempo
And=y
But=pero
[Choices]
TellMe=Puedes decirme, Por favor dime, Puedes darme, Por favor dame, Dame
WhatAre=Dime, dame, Cuales es
WhatIs=Dime, dame, qué es
CanYou=Puedes, por favor
Announcements=información delta, consejos tácticos, alertas laterales, alertas traseras, avisos de bandera azul, avisos de bandera amarilla, avisos de atajo, información de penalización
[Listener Grammars]
// Conversation //
Call=[{Hola, Hey} %name%, %name% me escuchas, %name% te necesito, Hey %name% donde estas?]
Yes=[Si, De acuerdo, Perfecto]
No=[No, No más tarde]
Joke=[(CanYou) contarme un chiste, Te sabes algun chiste]
Deactivate=[Silencio, Calla, para]
Activate=[Habla, Te escucho {ahora, otra vez}, ya puedes hablar {ahora, otra vez}]
AnnouncementsOff=[Nada de (Announcements), Nada de (Announcements), Nada de (Announcements)]
AnnouncementsOn=[Dame (Announcements), Dame (Announcements), Dame (Announcements) Dame (Announcements), Dame (Announcements)]
// Information //
Time=[(TellMe) decirme la hora, Que hora es, Cual es la {hora actual, hora}]
Position=[(WhatIs) mi posición en {mi carrera, mi carrera actual}, (TellMe)mi posición en {mi carrera, mi carrera actual}]
GapToAhead=[(TellMe) la diferencia con el {coche de delante, coche de delante, posición de delante, posición de delante, coche siguiente}, (WhatIs) la diferencia con el {coche de delante, coche de delante, posición de delante, posición de delante, siguiente coche}, Qué diferencia hay con el {coche de delante, coche de delante, posición de delante, posición de delante, siguiente coche}]
GapToBehind=[(TellMe) la diferencia con {el coche que viene detrás de mí, la posición detrás de mí, el coche anterior}, (WhatIs) a diferencia con {el coche detrás de mí, la posición detrás de mí, el coche anterior}, Cómo de grande es la diferencia con el {coche detrás de mí, la posición detrás de mí, el coche anterior}]
GapToLeader=[(TellMe) la diferencia con el {coche líder, líder}, (WhatIs) la diferencia con el {coche líder, líder}, Qué tan grande es la diferencia con el {coche líder, líder}]
LapTimes=[(TellMe) los tiempos de {vuelta actual, vuelta}, (WhatAre) los tiempos {actuales de la vuelta, vuelta}]
ActiveCars=[(TellMe) el número de {coches, coches en la pista, coches en la sesión}, (WhatAre) el número de {coches, coches en la pista, coches en la sesión}, Cuantos coches hay en la pista, Cuantos coches siguen activos, Cuántos coches hay en la sesión}]
FocusCar=[(CanYou) {concentrarte en, observar} el {coche, coche número, número} (Number), (CanYou) dar más información sobre el {coche, coche número, número} (Number)]
[Speaker Phrases]
// Conversation //
GreetingIntro.1=Hola %driver%, Soy %name%. Vigilaré los otros coches por ti.
GreetingIntro.2=Aquí está %name%. . Vigilaré el tráfico por ti..
GreetingWeather.1=Los datos climaticos son. %air% grados de temperatura del aire y %track% grados en la pista y esta %weather%.
GreetingWeather.2=Pista %weather% con  %air%  grados de temperatura del aire y %track% grados de temperatura de la pista.
GreetingPosition.1=Se parte de la P %position% %overall%.
GreetingPosition.2=Te has calificado para la P %position% %overall%.
GreetingDuration.1=La carrera durará %minutes% minutos. Y ahora concéntrate, está a punto de ponerse en verde. 
GreetingDuration.2=Hay  %minutes% miutos emocionantes por delante. Y ahora concéntrate, el inicio de la carrera está cerca.
GreetingLaps.1=La carrera de hoy son %laps% vueltas. Y ahora concentrados, está a punto de ponerse en verde.
GreetingLaps.2=Tenemos %laps% vueltas por delante. Y ahora concéntrate, el inicio de la carrera está cerca.
IHearYou.1=Estoy aquí. ¿Qué puedo hacer por ti?
IHearYou.2=¿Si %driver%? ¿Me has llamado?
IHearYou.3=Te escucho. Continúa.
IHearYou.4=Sí, te escucho. ¿Qué necesitas?
Confirm.1=Roger, espera un momento.
Confirm.2=Bien, lo haré ahora mismo.
Comfirm.3=Bien, déjame ver.
Roger.1=De acuerdo, lo haré.
Roger.2=Lo haré.
Roger.3=Vale, lo tengo.
Okay.1=De acuerdo. Pero estaré aquí, si me necesitas.
Okay.2=Entendido, no hay problema.
Repeat.1=Lo siento %driver%, no lo he entendido. ¿Puede repetirlo?
Repeat.2=Lo siento, no lo he entendido. Repite, por favor.
Repeat.3=¿Puedes repetirlo, por favor?
Later.1=Demasiado pronto para decirlo.
Later.2=Demasiado pronto, corre un par de vueltas.
Joke.1=En realidad deberías concentrarte en tu conducción, pero allá vamos.
Joke.2=Bien, pero después quiero ver tu enfoque.
NoJoke.1=Lo siento, no tengo nada que decir en este momento.
NoJoke.2=¿Qué? Deberías concentrarte en tu conducción.
// Session Settings Handling //
ConfirmSaveSettings.1=¿Apunto todos los ajustes para la próxima carrera?
ConfirmSaveSettings.2=Oh, %driver%, ¿debo anotar todos los ajustes?
// Announcement Handling //
ConfirmAnnouncementOff.1=No quieres más  %announcement%, ¿es esto correcto?
ConfirmAnnouncementOff.2=No más %announcement%, ¿verdad?
ConfirmAnnouncementOn.1=Quieres que te de %announcement%, ¿verdad?
ConfirmAnnouncementOn.2=Te daré %announcement%, ¿es esto correcto?
// Information //
Time.1=Son las %time%.
Time.2=Ahora es exactamente %time%.
Time.3=Tenemos %time%.
Position.1=Actualmente te encuentra en P %position%.
Position.2=Tu posición actual es P %position%.
PositionClass.1=Actualmente está en P %positionClass% en nuestra clase y en P %positionOverall% en el general..
PositionClass.2=Estamos en P %positionClass% de nuestra clase y en el P %positionOverall% del general.
Great.1=Genial, sigue así.
Great.2=Hasta ahora, el trabajo es perfecto.
TrackGapToAhead.1=Actualmente estás %delta% segundos por detras.
TrackGapToAhead.2=Estás %delta% segundos por detrás del coche que te precede directamente.
TrackGapToAhead.3=La diferencia es actualmente de %delta% segundos.
StandingsGapToAhead.1=Actualmente estás %delta% segundos por detrás de tu oponente.
StandingsGapToAhead.2=Estás %delta% segundos por detrás del coche que está una posición por delante de ti.
StandingsGapToAhead.3=La diferencia con el coche que va una posición por delante de ti es actualmente de %delta% segundos.
StandingsAheadLapped.1=El coche que está una posición por delante de ti está al menos una vuelta por encima.
StandingsAheadLapped.2=Ya te ha adelantado el coche que va una posición por delante de ti.
TrackGapToBehind.1=Estás %delta%  segundos por delante del coche que va justo detrás de ti.
TrackGapToBehind.2=La diferencia es actualmente de %delta% segundos.
TrackGapToBehind.3=La distancia con el coche que viene justo detrás es de %delta% segundos.
StandingsGapToBehind.1=Estás %delta% segundos por delante de tu oponente.
StandingsGapToBehind.2=La diferencia con el coche que va una posición por detrás de ti es actualmente de%delta% segundos.
StandingsGapToBehind.3=La distancia con tu oponente detrás de ti es actualmente de  %delta% segundos.
StandingsBehindLapped.1=El coche que está una posición por detrás de ti tiene al menos una vuelta menos.
StandingsBehindLapped.2=
Ya has superado al coche que está una posición por detrás de ti.
NoGapToAhead.1=En este momento, eres el líder.
NoGapToAhead.2=Actualmente está en primer lugar.
NoGapToBehind.1=Actualmente estás en el último lugar.
NoGapToBehind.2=No hay ningún coche detrás de ti.
NotTheSameLap.1=Pero el coche no está en la misma vuelta.
NotTheSameLap.2=Pero no es para la posición.
NoTrackGap.1=No puedo decírselo en este momento. Vuelve a ponerte en contacto más tarde.
NoTrackGap.2=Mis datos no están actualizados en este momento. Espera otra vuelta.
GapToLeader.1=Estás %delta% segundos por detrás del líder.
GapToLeader.2=La diferencia es de %delta% segundos.
GapToLeader.3=%delta% segundos pierde el lider.
GapCarInPit.1=Pero este coche está en los boxes.
GapCarInPit.2=Pero este coche no está actualmente en la pista.
AheadCarInPit.1=El coche que va delante está en boxes.
AheadCarInPit.2=El coche de delante no está actualmente en la pista.
BehindCarInPit.1=El coche de detrás está en los boxes.
BehindCarInPit.2=El coche de atrás no está actualmente en la pista.
LapTime.1=Estas dando la vuelta en %minute% minutos y %seconds% segundos.
LapTime.2=%minute% minuto y %seconds% segundos es el tiempo de tu ultima vuelta.
LapTimeFront.1=El coche que va una posición por delante de ti a dado la vuelta en %minute% minuto y %seconds% segundos.
LapTimeFront.2=%minute% minutos y %seconds% segundos es el tiempo del coche que está una posición por delante de usted.
LapTimeBehind.1=Y el coche que va una posición por detrás está rodando en un %minute% minuto y %seconds% segundos.
LapTimeBehind.2=%minute% minutos y %seconds% segundos es el tiempo del coche que está una posición por detrás de ti.
LapTimeLeader.1=Y el líder está rodando en un %minute% minuto y %seconds% segundos.
LapTimeLeader.2=Y %minute% minutos y %seconds% segundos fue la ultima vuelta del líder.
LapTimeDelta.1=Está %delta% segundos %difference% que tú.
LapTimeDelta.2=Por lo tanto es %delta% segundos %difference%.
ActiveCars.1=Hay %cars% coches on la pista.
ActiveCars.2=%cars% coches están actualmente en la pista.
ActiveCars.3=Hay %cars% coches en la sesión.
ActiveCarsClass.1=Hay %cars% coches on la pista, %classCars% de ellos en nuestra clase.
ActiveCarsClass.2=%overallCars% coches están actualmente en la pista, %classCars% de ellos en nuestra clase.
ActiveCarsClass.3=Hay %overallCars% coches en la sesión, %classCars% de ellos en nuestra clase.
[Spotter Phrases]
// Race Start //
Green.1=Verde,Verde,Verde.
Green.2=Vamos, es verde.
Green.3=Verde, pisa el acelerador.
Green.4=Verde, demuéstrales de qué estás hecho.
GoodStart.1=Buena salida, hemos podido defender nuestra posición de salida.
GoodStart.2=Bien hecho. No has perdido ninguna posición en la salida.
GreatStart.1=Gran salida, bien hecho.
GreatStart.2=Fue una gran salida.
BadStart.1=Fue mala suerte, podría haber sido mejor.
BadStart.2=La salida no fue muy buena.
PositionsGained.1=Hemos ganado %positions% posiciones.
PositionsGained.2=%positions% posiciones ganadas.
PositionsLost.1=Hemos perdido %positions% posiciones.
PositionsLost.2=%positions% posiciones perdidas.
Fight.1=Concéntrate y busca el mejor momento.
Fight.2=Tú eres mejor que el.
// Race Finish //
LastLaps.1=Bien, sólo unas cuantas vueltas más.
LastLaps.2=Casi lo has conseguido, sólo faltan unas vueltas.
Leader.1=Eres el lider.
Leader.2=Estamos en primera posición.
Position.1=Estás en P %position%.
Position.2=P %position%, no esta nada mal.
BringItHome.2=Sin riesgo, necesitamos los puntos.
BringItHome.3=Este final será un buen resultado.
Focus.1=Concéntrate y acelera.
Focus.2=Concéntrate y pisa el acelerador.
// Weather Information //
Temperature.1=Hola %driver% soy %name%. Tenemos %air% grados en el aire y %track% grados de temperatura de la pista.
Temperature.2=Soy %name%. Actualmente tenemos %air%  grados en el aire y %track% drados de temperatura de pista.
TemperatureRising.1=Las temperaturas están subiendo, %air% grados en el aire y %track% grados temperatura pista ahora.
TemperatureRising.2=Ahora tenemos %air% grados en el aire y %track% grados de temperatura de pista y sigue aumentando.
TemperatureFalling.1=Las temperaturas están bajando, %air% grados en el aire y %track% grados temperatura pista ahora..
TemperatureFalling.2=Las temperaturas están bajando, %air% grados en el aire y %track% grados temperatura pista ahora.
// Session Information //
StintEnding.1=Atención, %driver%, tu stint termina pronto, te quedan %laps% vueltas.
StintEnding.2=Atención, %driver%, solo te quedan %laps% vueltas para terminar tu stint.
StintEnding.3=Tu stint termina en %laps% vueltas. No bajes la concentración.
HalfTimeIntro.1=La primera mitad de la carrera ha terminado. En este momento se encuentra en P %position%.
HalfTimeIntro.2=Llegamos a la mitad de la carrera y actualmente estás en P %position%.
HalfTimeSession.1=Todavía quedan %minutes% minutos y unas %laps% vueltas para terminar. 
HalfTimeSession.2=Pero aún quedan %minutes% minutos y %laps% vueltas
HalfTimeStint.1=Tu stint termina en %minutes% minutos.
HalfTimeStint.2=Te quedan %minutes% minutos para llegar al final de tu stint.
HalfTimeEnoughFuel.1=y tienes combustible para otras %laps% vueltas.
HalfTimeEnoughFuel.2=y tenemos suficiente combustible para finalizar la carrera.
HalfTimeNotEnoughFuel.1=pero solo tenemos gasolina para %laps% vueltas.
HalfTimeNotEnoughFuel.2=pero no tenemos suficiente combustible para finalizar.
SessionEnding.1=La sesión actual finaliza en %minutes% minutos.
SessionEnding.1=%minutes% minutos restantes para la sesión actual.
// Lap Timinig //
BestLap.1=%minute% minutos %seconds%  segundos, esta ha sido tu mejor vuelta hasta ahora, genial.
BestLap.2=Genial, %minute% minuto %seconds% segundos. Tu mejor vuelta hasta ahora.
// Delta Information //
GainedFront.1=Estás alcanzando al coche que te precede, has ganado %gained% segundos. La diferencia sigue siendo de %delta% egundos, pero eres %lapTime% segundos más rápido.
GainedFront.2=Has ganado un %gained% segundos sobre el coche de delante, pero aún te saca %delta% segundos.
CanDoIt.1=Puedes hacerlo. No te rindas.
CanDoIt.2=Ve a por él.
CanDoIt.3=Atrápalo.
CantDoIt.1=No es posible, pero sigue así.
CantDoIt.2=Normalmente no es posible, pero mantén la concentración y ya veremos.
GotHim.1=Te has puesto al día. Genial. Ahora atácalo.
GotHim.2=Ya te esta viendo por el espejo. Ponlo nervioso.
GotHim.3=Bien hecho, lo alcanzaste. Adelántalo.
LostFront.1=Has perdido con el coche de delante, %lost% segundos durante las últimas vueltas. La diferencia ya es de %delta% segundos y él es  %lapTime% segundos más rápido.
LostFront.2=Has perdido %lost% segundos con el coche que está una posición por delante de ti.
LapDownDriver.1=El coche que te precede está al menos una vuelta por debajo. Muéstrale que estás ahí.
LapDownDriver.2=Tenemos a un doblado delante. Adelantalo lo antes posible.
LapUpDriver.1=El coche de delante te lleva al menos una vuelta de ventaja. Ponte detras de el y cogele el rebufo pero no te equivoques.
LapUpDriver.2=Puedes volver a girar, si quieres, pero ten cuidado.
UnsafeDriverFront.1=Pero ten cuidado, no es un piloto limpio.
UnsafeDriverFront.2=Sin embargo, no es un piloto limpio, así que ten cuidado.
InconsistentDriverFront.1=Conduce bastante mal, así que busca el sitio adecuado y ten cuidado.
InconsistentDriverFront.2=Pero comete muchos errores, así que espera el momento adecuado y no te metas en problemas.
InconsistentDriverFront.3=Tuvo un par de incidentes, por lo que hay que tener cuidado.
LostBehind.1=El coche que va detrás de ti ha ganado %lost% segundos y es %lapTime% segundos más rápido. Concentrate y vuelve a coger ritmo.
LostBehind.2=Has perdido %lost% segundos con respecto al coche que va detrás de ti. Todavía hay %delta% segundos entre vosotros, pero él es %lapTime% segundos más rápido.
LostBehind.3=El coche que va detrás de ti se está acercando. Has perdido %lost% segundos y él es %lapTime% ssegundos más rápido.
ClosingIn.1=Vas a recibir algo de presión por detrás. Concentrate.
ClosingIn.2=El coche detrás de ti te va a atacar. Defiendete.
UnsafeDriverBehind.1=Pero cuidado, no es un piloto seguro.
UnsafeDriverBehind.2=Sin embargo, no es el piloto más seguro, así que ten cuidado.
InconsistentDriverBehind.1=Conduce bastante mal, así que es mejor dejarlo pasar, antes de que tengas un accidente y arruines tu carrera.
InconsistentDriverBehind.2=Pero está cometiendo muchos errores, así que sería mejor dejarlo pasar.
GainedBehind.1=El coche detrás de ti ha perdido %gained% segundos y es %lapTime% segundos más lento. Bien hecho.
GainedBehind.2=Has ganado %gained%segundos al coche que va detrás de ti. La diferencia ya es de %delta% segundos y eres %lapTime% segundos más rápido.
GainedBehind.3=Te estas alejando del coche que va una posición por detrás de ti. Has ganado un %gained% segundos. Genial.
LessPitstops.1=%conjunction% tu tienes preparado los pits. 
LessPitstops.2=%conjunction% tienes  %pitstops% pitstops aún. 
LessPitstops.3=%conjunction% creo que necesitas entrar a boxes. 
MorePitstops.1=%conjunction% tenemos listos los pits. 
MorePitstops.2=%conjunction% tu tienes %pitstops% pits disponible.
MorePitstops.3=%conjunction% aún tiene que entrar a pit.
// Tactical Advises //
ProtectFaster.1=El coche doblado que está detrás de ti es probablemente más rápido, pero te protege de tu oponente directo. Mantenlo detrás de ti el mayor tiempo posible.
ProtectFaster.2=El coche doblado que está detrás de ti te protege de tu oponente directo. Parece ser más rápido, pero mantenlo detrás de ti el mayor tiempo posible.
ProtectSlower.1=Delante de ti hay un coche que esta rodando más lento. Intenta adelantarlo lo más rápido posible, ya que esto te dará algo de aire por detrás.
ProtectSlower.2=Adelanta al coche que te precede lo más rápido posible y ponlo entre tú y tu perseguidor.
LapDownFaster.1=El coche que está detrás de ti es más rápido.
LapDownFaster.2=El coche de detrás es un doblado, pero es más rápido.
LapUpFaster.1=El coche doblado de detrás es ligeramente más rápido.
LapUpFaster.2=El coche doblado detrás de ti no es mucho más rápido.
Slipstream.1=Coge su rebufo cuando te sobrepase.
Slipstream.2=Déjalo pasar y usa su rebufo.
Slipstream.3=Puedes utilizar su rebufo si te ha adelantado.
LeaderPitting.1=El líder está en boxes ahora.
LeaderPitting.2=El líder está en boxes.
LeaderPitting.3=P 1 en boxes.
AheadPitting.1=el coche que está una posición por delante está en los boxes.
AheadPitting.2=Tu oponente directo está en boxes ahora.
AheadPitting.3=El coche que va delante está en boxes.
BehindPitting.1=El coche que va una posición por detrás está en boxes.
BehindPitting.2=Tu perseguidor está en los boxes.
BehindPitting.3=El coche que está detrás de ti está en los boxes ahora.
LeaderBestLap.1=El líder acaba de registrar una vuelta de minute% minutos %seconds% segundos.
LeaderBestLap.2=La mejor vuelta del líder es ahora de %minute% minutos %seconds% segundos.
AheadBestLap.1=El coche que está una posición por delante de ti acaba de marcar una vuelta de %minute% minutos %seconds% segundos.
AheadBestLap.2=La nueva mejor vuelta del coche que está una posición por delante de ti es ahora de %minute% minutos %seconds% segundos.
BehindBestLap.1=El coche que va una posición por detrás acaba de marcar un tiempo de %minute% minutos %seconds% segundos.
BehindBestLap.2=Nueva mejor vuelta para el coche que está una posición por detrás de ti con %minute% minutos %seconds% segundos.
LeaderLapTime.1=El líder está rodando actualmente en %minute% minutos %seconds% segundos.
LeaderLapTime.2=%minute% minutos %seconds% segundos fue la última vuelta del líder.
AheadLapTime.1=El coche que va una posición por delante de usted está rodando en %minute% minutos %seconds% segundos.
AheadLapTime.2=%minute% minutos %seconds% segundos fue la última vuelta del coche que estaba una posición por delante de ti.
BehindLapTime.1=El coche que va una posición por detrás está rodando en %minute% minutos %seconds% segundos.
BehindLapTime.2=%minute% minutos %seconds% segundos fue la última vuelta del coche una posición por detrás
AheadProblem.1=El coche que iba por delante era mucho más lento en la última vuelta. Tal vez tuvo un problema.
AheadProblem.2=Parece que el coche que está una posición por delante tuvo un problema. Su última vuelta fue bastante lenta.
AheadProblem.3=La última vuelta del coche que iba por delante fue muy lenta. Podría tener un problema.
BehindProblem.1=El coche una posición por detrás era mucho más lento últimamente. Tal vez tenga un problema.
BehindProblem.2=Parece que el coche que iba una posición por detrás tuvo un problema. La última vuelta fue bastante lenta.
BehindProblem.3=La última vuelta del coche que iba una posición por detrás fue muy lenta. Podría tener un problema.
// Spotting //
Right.1=Atención a la derecha.
Right.2=Coche a la derecha.
Right.3=Coche derecho.
Left.1=Atención a la izquierda.
Left.2=Coche a la izquierda.
Left.3==Coche izquierda.
Three.1=Three wide ten cuidado.
Three.2=Three wide.
Side.1=Cuidado con el paralelo.
Side.2=Coche en el lado ten cuidado.
Side.3=En tu lateral.
Hold.1=Mantén la línea.
Hold.2=Todavía está ahí.
ClearAll.1=Todo despejado.
ClearAll.2=Vale todo despejado.
ClearAll.3=Todo despejado. Ataque.
ClearLeft.1=Izquierda despejado.
ClearLeft.2=La izquierda está despejada.
ClearLeft.3=Despejado a la izquierda.
ClearRight.1=Derecha despejado.
ClearRight.2=La derecha está despejada.
ClearRight.3=La derecha está despejada.
Behind.1=Coche detrás de ti.
Behind.2=El coche está en la parte trasera.
Behind.3=Atención a los que están detrás.
BehindRight.1=Detrás, a la derecha.
BehindRight.2=Coche a la derecha detrás de ti.
BehindLeft.1=Detrás, a la izquierda.
BehindLeft.2=Coche a la izquierda detrás de ti.
// Flag Warnings //
YellowFull.1=Cuidado hay bandera amarilla en pista.
YellowFull.2=Atención bandera amarilla
YellowAll.1=Bandera amarilla en todos los sectores.
YellowAll.2=Precaución ondean la bandera amarilla.
YellowSector.1=Bandera amarilla en el %sector% sector.
YellowSector.2=Cuidado en el %sector% sector, hay bandera amarilla.
YellowAhead.1=Bandera amarilla delante.
YellowAhead.2=Atención bandera amarilla adelante.
YellowDistance.1=Bandera amarilla en %distance% metros.
YellowDistance.2=Cuidado en %distance% metros, hay bandera amarilla.
YellowDistance.3=Bandera amarilla en el %sector% sector esta a %distance% metros..
YellowClear.1=La pista está despejada.
YellowClear.2=Se retira la bandera amarilla.
YellowClear.3=Bandera verde. A correr.
Blue.1=Un coche más rápido se aproxima.
Blue.2=Tienes una bandera azul.
Blue.3=Hay un coche más rápido detrás de ti.
BlueForPosition.1=El coche más rápido se está acercando, pero también tienes un oponente para la posición detrás de ti.
BlueForPosition.2=Tienes una bandera azul pero presta atención a tu oponente directo.
BlueForPosition.3=Un coche más rápido está detrás de ti, pero ten en cuenta el otro coche.
PitWindowOpen.1=Los boxes estan abiertos.
PitWindowOpen.2=El pitlane está abierto para las paradas en boxes planificadas.
PitWindowOpen.3=La ventana de la parada en boxes está abierta.
PitWindowClosed.1=Los boxes estan cerrados.
PitWindowClosed.2=El pitlane está cerrado para las paradas en boxes planificadas.
PitWindowClosed.3=El pitlane está ahora cerrado.
// Warnings and Penalties //
Cut.1=%driver%, mantente en la pista. 
Cut.2=No exageres, %driver%.
Cut.3=Ten cuidado, intenta mantenerte en la pista.
RepeatedCut.1=Tienes que ir a lo seguro %driver%. No podemos arriesgarnos a una penalización. 
RepeatedCut.2=Ten cuidado. Una penalización nos hará retroceder mucho.
RepeatedCut.3=%driver%, relajate, nos estamos jugando una penalización.
Penalty.1=Maldita sea, tenemos una penalización %penalty%.
Penalty.2=Maldita sea. Nos acaban de meter %penalty% de penalización. Eso nos hara retroceder.
Disqualified.1=Estamos descalificados. No me lo puedo creer. 
Disqualified.2=Maldita sea, hemos sido descalificados.