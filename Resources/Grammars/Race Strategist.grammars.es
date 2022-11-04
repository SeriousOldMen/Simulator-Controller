[Fragments]
But=pero
And=y
Faster=más rápido
Slower=más lento
Laps=Vueltas
Lap=vuelta
Car=coche
Position=posición
DryTyre=seco
IntermediateTyre=intermedio
WetTyre=mojado
WeatherUpdate=avisos meteorológicos
[Choices]
TellMe=Puedes decirme, Por favor dime, Puedes darme, Por favor dame, Dame
WhatAre=Dime, dame, Cuales es
WhatIs=Dime, dame, qué es
CanYou=Puedes, por favor
CanWe=Puedes, podemos, por favor
Announcements=avisos meteorológicos
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
LapsRemaining=[(TellMe) las vueltas restantes, Cuántas vueltas quedan, Cuántas vueltas quedan, Cuántas vueltas faltan]
Weather=[Qué pasa con el tiempo, ¿Se avecina lluvia, {Algo, Son}, (CanYou) comprueba el {tiempo, el tiempo, por favor}]
FuturePosition=[Simula la {carrera, la clasificación} en (Number) vueltas, (CanYou) simular la {carrera, clasificación} en (Number) vueltas, ¿Cuál será mi posición en (Number) vueltas, ¿Cuál sera mi posición en (Number) vueltas]
Position=[(WhatIs) {my, my race, my current race} position, (TellMe) {my, my race, my current race} position]
GapToAhead=[(TellMe) la diferencia con el {coche de delante, coche de delante, posición de delante, posición de delante, coche siguiente}, (WhatIs) la diferencia con el {coche de delante, coche de delante, posición de delante, posición de delante, siguiente coche}, Qué diferencia hay con el {coche de delante, gato de delante, posición de delante, posición de delante, siguiente coche}]
GapToBehind=[(TellMe) la diferencia con {el coche que viene detrás de mí, la posición detrás de mí, el coche anterior}, (WhatIs) la diferencia con {el coche detrás de mí, la posición detrás de mí, el coche anterior}, Cómo de grande es la diferencia con el {coche detrás de mí, la posición detrás de mí, el coche anterior}]
GapToLeader=[(TellMe) la diferencia con el {coche líder, líder}, (WhatIs) la diferencia con el {coche líder, líder}, Cuán grande es la diferencia con el {coche líder, líder}]
LapTimes=[(TellMe) los tiempos de {vuelta actual, vuelta}, (WhatAre) los tiempos de {vuelta actual, vuelta}]
// Pitstop Planning //
PitstopRecommend=[(WhatIs) la mejor {vuelta, opción} para el próximo pitstop, ¿Cuándo recomienda el próximo pitstop, (CanYou) recomendar la próxima parada en boxes, en qué vuelta debo entrar en boxes]
PitstopSimulate=[(CanYou) simular la {siguiente parada en boxes, pitstop} {alrededor, en} la vuelta (Number), Planificar la {siguiente parada en boxes, pitstop} {alrededor, en} la vuelta (Number), (CanYou) planificar la {siguiente parada en boxes, pitstop} {alrededor, en} la vuelta (Number)]
// Race Strategy Handling //
StrategyOverview=[Cómo es nuestra estrategia para {hoy, la carrera}, Puedes darme un resumen de {la, nuestra} estrategia, Cómo es nuestra estrategia, Dame {por favor} {la, nuestra} estrategia]
CancelStrategy=[(CanYou) {suspender, cancelar} la estrategia, {Suspender, cancelar} la estrategia, La estrategia ya no tiene sentido, La estrategia ya no tiene sentido]
NextPitstop=[Cuándo es la próxima parada en boxes, En qué {vuelta está prevista la parada en boxes, debo entrar en boxes}, Cuándo debo entrar en boxes, (TellMe) {la vuelta para la siguiente parada en boxes, cuando debería entrar en boxes}]
StrategyRecommend=[(CanYou) desarrollar una nueva estrategia, (CanYou) ajustar la estrategia, (CanYou) planear una nueva estrategia, Necesitamos una nueva estrategia].
[Speaker Phrases]
// Conversation //	
Greeting.1=Hola %driver%, Soy %name%. Veré la carrera y encontraré la mejor estrategia para ti.
Greeting.2=Soy %name% tu estratega. Estaré atento a la estrategia para esta carrera.
Greeting.3=Me llamo %name%. Llámame, si necesitas alguna estrategia.
WelcomeBack.1=Hola %driver%, bienvenido de nuevo.
WelcomeBack.2=bienvenido de nuevo, %driver%.
IHearYou.1=Estoy aquí. ¿Qué puedo hacer por ti?
IHearYou.2=Yeah %driver%? ¿Me has llamado?
IHearYou.3=Te escucho. Continúa.
IHearYou.4=Sí, te escucho. ¿Qué necesitas?
Confirm.1=Roger, espera un momento.
Confirm.2=Bien, lo haré ahora mismo.
Comfirm.3=Vale, déjame ver.
Roger.1=De acuerdo, lo haré.
Roger.2=Lo haré.
Roger.3=Bien, lo tengo.
Okay.1=Está bien. Pero estaré aquí, si me necesitas.
Okay.2=Entendido, no hay problema.
Repeat.1=Lo siento %driver%, No lo he entendido. ¿Puede repetirlo?
Repeat.2=Lo siento, no lo he entendido. Repite, por favor.
Repeat.3=¿Puede repetirlo, por favor?
Later.1=Es demasiado pronto para decirlo. Por favor, preguntame en una o dos vueltas.
Later.2=No puedo decírselo todavía. Por favor, encuentre su ritmo y establezca su posición primero.
Later.3=Tienes que encontrar tu ritmo primero. Por favor, preguntame más tarde.
CollectingData.1=Lo siento %driver%, pero sólo estoy recogiendo datos para nuestra estrategia de carrera. Por el momento estás por tu cuenta.
CollectingData.2=Oye, estoy preparando la estrategia para la próxima carrera. Tienes que prescindir de mí en este momento.
Bye.1=Bien, ven a los boxes ahora.
Bye.2=Bien hecho, entonces trae el coche de vuelta.
Bye.3=Hecho. Me encanta trabajar contigo.
Joke.1=En realidad deberías concentrarte en la carrera, pero allá vamos:
Joke.2=Bien, pero después quiero ver tu mejor vuelta.
NoJoke.1=Lo siento no me se ninguno.
NoJoke.2=¿Perdona? Ahora no es el momento.
// Announcement Handling //
ConfirmAnnouncementOff.1=No quieres más %announcement%, verdad?
ConfirmAnnouncementOff.2=Nada de %announcement%?
ConfirmAnnouncementOn.1=¿Quieres que te dé %announcement%?
ConfirmAnnouncementOn.2=Te daré %announcement%.
// Information //
Time.1=Son las %time%.
Time.2=Ahora es exactamente %time%.
Time.3=Tenemos %time%.
Laps.1=Aún tienes %laps% vueltas para finalizar.
Laps.2=Tienes combustible para %laps% vueltas.
LapsFuel.1=Tenemos combustible para %laps% vueltas.
LapsFuel.2=Tienes combustible para dar %laps% vueltas.
LapsStint.1=Pero tu stint termina en %laps% vueltas.
LapsStint.2=Pero solo te quedan %laps% para terminar tu stint.
LapsSession.1=Pero la sesión terminara en %laps% vueltas.
LapsSession.2=Pero solo quedan %laps% vueltas para el resto de la sesión.
WeatherGood.1=El tiempo parece estable.
WeatherGood.2=El tiempo no cambia. Quedate tranquilo
WeatherRain.1=Se avecina lluvia.
WeatherRain.2=%driver%, esperamos lluvias en unos minutos.
Position.1=Te encuentras actualmente en P %position%.
Position.2=Tu posición actual es P %position%.
NoFutureLap.1=Esto no tiene sentido. Por favor, elija otra vuelta.
FuturePosition.1=Lo más probable es que esté en P %position%.
FuturePosition.2=La simulación muestra en P %position%.
FuturePosition.3=Parece que estará en P %position%.
NoFuturePosition.1=Todavía no tenemos suficientes datos para una simulación.
Great.1=Genial, sigue así.
Great.2=Hasta ahora, el trabajo es perfecto.
TrackGapToAhead.1=Actualmente estás %delta% segundos por detras.
TrackGapToAhead.2=Estás %delta% egundos detrás del coche que te precede directamente.
TrackGapToAhead.3=La diferencia es actualmente de %delta% segundos.
StandingsGapToAhead.1=Actualmente estás %delta% segundos por detras.
StandingsGapToAhead.2=Estás %delta% segundos por detrás del coche que está una posición por delante de ti.
StandingsGapToAhead.3=La diferencia con el coche que va una posición por delante de ti es actualmente de %delta% segundos.
StandingsAheadLapped.1=El coche que está una posición por delante de ti está al menos una vuelta por encima.
StandingsAheadLapped.2=Ya te ha doblado el coche que va una posición por delante de ti.
TrackGapToBehind.1=Estás %delta% segundos por delante del coche que va directamente detrás de ti.
TrackGapToBehind.2=La diferencia es actualmente de %delta% segundos.
TrackGapToBehind.3=La distancia con el coche que viene justo detrás es de %delta% segundos.
StandingsGapToBehind.1=Estás %delta% segundos por delante del coche que está una posición por detrás de ti.
StandingsGapToBehind.2=La diferencia es actualmente de %delta% segundos.
StandingsGapToBehind.3=La diferencia con el coche que va una posición por detrás de ti es actualmente de %delta% segundos.
StandingsBehindLapped.1=El coche que está una posición por detrás de ti tiene al menos una vuelta menos.
StandingsBehindLapped.2=Ya has doblado al coche que está una posición por detrás de ti.
StandingCarInPit.1=Pero este coche está en los boxes.
StandingCarInPit.2=Pero este coche no está actualmente en la pista.
NoGapToAhead.1=En este momento estás liderando.
NoGapToAhead.2=Actualmente estás en primer lugar.
NoGapToBehind.1=Actualmente estás en el último lugar.
NoGapToBehind.2=No hay ningún coche detrás de ti.
NotTheSameLap.1=Pero el coche no está en la misma vuelta.
NotTheSameLap.2=Pero esto no es por la posición.
NoTrackGap.1=No puedo decírselo en este momento. Vuelve a ponerte en contacto más tarde.
NoTrackGap.2=Mis datos no están actualizados en este momento. Espera otra vuelta.
GapToLeader.1=Estás %delta% segundos por detrás del líder.
GapToLeader.2=La diferencia es de %delta% segundos.
GapToLeader.3=El lider a perdido %delta% segundos.
GapCarInPit.1=Pero este coche está en los boxes.
GapCarInPit.2=Pero este coche no está actualmente en la pista.
AheadCarInPit.1=El coche de delante está en boxes.
AheadCarInPit.2=El coche de delante no está actualmente en la pista.
BehindCarInPit.1=El coche de atrás está en los boxes.
BehindCarInPit.2=El coche de atrás no está actualmente en la pista.
LapTime.1=Estas rodando en %minute% minutos %seconds% segundos.
LapTime.2=%minute% minutos %seconds% segundos fue tu ultima vuelta.
LapTimeFront.1=El coche que va una posición por delante de ti está rodando en %minute% minuto %seconds% segundos.
LapTimeFront.2=%minute% minutos %seconds% segundos es el tiempo del coche que está una posición por delante de ti.
LapTimeBehind.1=Y el coche que va una posición por detrás está rodando en %minute% minutos %seconds% segundos.
LapTimeBehind.2=%minute% minutos %seconds% segundos es el tiempo del coche que está una posición por detrás de ti.
LapTimeLeader.1=Y el líder está rodando en %minute% minutos %seconds% segundos.
LapTimeLeader.2=y %minute% minutos %seconds% segundos fue la ultima vuelta del lider.
LapTimeDelta.1=Te saca %delta% segundos %difference% que tu.
LapTimeDelta.2=Por lo tanto, es %delta% segundos %difference%.
// Weather Analysis & Tyre Recommendation //
WeatherChange.1=%driver%, parece que el tiempo cambiará en unos %minutes% minutos. Estaré atento a ello.
WeatherChange.2=Te habla %name%. Acabo de recibir la última información meteorológica. Tal vez tengamos que ajustar nuestra estrategia.
WeatherNoChange.1=%driver%, parece que el tiempo cambiará en unos  %minutes% minutos. Pero un cambio de estrategia tan tarde podría no valer la pena.
WeatherNoChange.2=Aqui %name%. Acabo de recibir la última información meteorológica. Se avecina un cambio, pero es posible que lo logremos con nuestra configuración actual.
WeatherRainChange.1=%driver%, te habla %name%. Empezará a llover en%minutes% minutos. Deberíamos cambiar a neumáticos de %compound% lo antes posible.
WeatherRainChange.2=%name% en la radio. Parece que va a empezar a llover en unos minutos. Recomiendo un cambio de neumáticos.
WeatherDryChange.1=%driver%, la pista se secará en los próximos %minutes% minutos.  Tal vez deberíamos cambiar a neumaticos de %compound%.
WeatherDryChange.2=Hey %driver%, soy %name% . Dejará de llover en %minutes% minutos. Creo que, podemos planear un cambio a neumaticos de %compound%.
// Pitstop Strategy Planning //
PitstopLap.1=Hola %driver%, la mejor vuelta para una parada en boxes será la vuelta %lap%.
PitstopLap.2=Hola %driver% soy %name%, debe venir en la vuelta %lap% a los boxes.
PitstopLap.3=%driver%, una parada en boxes en la vuelta %lap% sera la mejor opción.
NoPlannedPitstop.1=No puedo hacer una simulación de pitstop con estos datos. Entra, cuando estés listo.
NoPitstopNeeded.1=Una parada en boxes no es necesaria. Parece que tienes suficiente combustible para terminar tu stint.
NoPitstopNeeded.2=No necesitamos una parada en boxes, te queda suficiente combustible para este stint.
ConfirmUpdateStrategy.1=¿Actualizo la estrategia?
ConfirmUpdateStrategy.2=Actualizaré nuestra estrategia y volveré contigo, ¿de acuerdo?
ConfirmInformEngineer.1=¿Informo al ingeniero de carrera?
ConfirmInformEngineer.2=Informaré al ingeniero de carrera, ¿no?
ConfirmInformEngineerAnyway.1=De acuerdo, no hay problema. ¿Aún debo informar al ingeniero de carrera?
ConfirmInformEngineerAnyway.2=Bien, podemos hacer esto más tarde. Pero informaré al ingeniero de carrera, ¿verdad?
// Race Strategy //
ConfirmReportStrategy.1=%driver%, soy %name%. ¿Debo darle algunos datos clave sobre nuestra estrategia?
ConfirmReportStrategy.2=%name% en la readio. ¿Quieres un resumen de nuestra estrategia?
ConfirmReportStrategy.3=%driver%, te habla %name%. Puedo resumir brevemente nuestra estrategia para la carrera, ¿de acuerdo?
Strategy.1=%driver%, hemos desarrollado la siguiente estrategia:
Strategy.2=Tenemos la siguiente estrategia:
Strategy.3=Bien, aquí está el resumen de la estrategia:
NoStrategy.1=%driver%, no hemos desarrollado una estrategia para esta carrera. Eres libre de elegir tus paradas en boxes por tu cuenta.
NoStrategy.2=No tenemos ninguna estrategia para esta carrera. Estás por tu cuenta.
NoStrategyRecommendation.1=Lo siento, necesito el apoyo de nuestro ingeniero para hacer esto.
NoStrategyRecommendation.2=Nuestro ingeniero no está por aquí. No puedo hacer esto solo.
NoStrategyRecommendation.3=No puedo encontrar a nuestro ingeniero. Es imposible para mí hacer esto solo.
Pitstops.1=Hemos planificado %pitstops% paradas.
Pitstops.2=Tendremos  %pitstops% pitstops en total.
NextPitstop.1=La siguiente parada es en la vuelta %pitstopLap%.
NextPitstop.2=La siguiente parada será en la vuelta %pitstopLap%.
NextPitstop.3=Tienes que venir para la siguiente parada en la vuelta %pitstopLap%.
NoNextPitstop.1=Pero ya ha completado todas las paradas programadas.
NoNextPitstop.2=No hay más paradas en boxes.
Refuel.1=Vamos a repostar %refuel% litros.
Refuel.2= %refuel% litros se repostarán.
NoRefuel.1=No está previsto el repostaje.
NoRefuel.2=No es necesario repostar.
NoRefuel.3=No necesitamos combustible adicional.
TyreChange.1=Está previsto un cambio de neumáticos.
TyreChange.2=Vamos a cambiar los neumáticos.
NoTyreChange.1=No está previsto cambiar los neumáticos.
NoTyreChange.2=No es necesario cambiar los neumáticos.
NoTyreChange.3=Dejaremos los neumaticos sin cambiar.
StrategyMap.1=Por cierto, a partir de ahora deberías utilizar el Map %map%.
StrategyMap.2=Por cierto, elija el mapa %map% para este stint.
StintMap.1=%driver%, soy %name%. Por favor, utilice el mapa %map% para este stint.
StintMap.2=%name% en la radio. Por favor, utilice el mapa %map% para este stint.
ConfirmCancelStrategy.1=%driver%, quieres que descarte la estrategia, ¿verdad?
ConfirmCancelStrategy.2=¿Debería cancelar la estrategia?
StrategyCanceled.1=Bien, he rechazado la estrategia. Ahora estás por tu cuenta.
StrategyCanceled.2=La estrategia se cancela. Ahora tenemos que planificar las paradas de forma espontánea.
PitstopAhead.1=%driver%, te habla %name%. La próxima parada en boxes está prevista en  %laps% vueltas.
PitstopAhead.2 =%name% en la radio. La próxima parada está prevista para la vuelta %lap%.
// Session Settings Handling //
ConfirmSaveSettings.1=¿Apunto todos los ajustes para la próxima carrera?
ConfirmSaveSettings.2=Una pregunta %driver%, ¿debo anotar todas las configuraciones?
// Race Report Handling //
ConfirmSaveSettingsAndRaceReport.1=¿Apunto todos los ajustes y preparo el informe para el análisis posterior a la carrera?
ConfirmSaveSettingsAndRaceReport.2=Una pregunta %driver%, ¿anoto todos los ajustes y quieres un informe de la carrera?
ConfirmSaveRaceReport.1=Y yo prepararé el informe para el análisis de después de la carrera, ¿no?
ConfirmSaveRaceReport.2=%driver%, ¿quieres un informe de la carrera?
RaceReportSaved.1=Bien, el informe está listo.
RaceReportSaved.2=Todo listo.
// Race Review //
GreatRace.1=%name% en la radio. Gran carrera. P %position%. No hay nada más que decir sobre esto. Vamos a celebrarlo.
GreatRace.2=Te habla %name%. Fantástico, hemos terminado en P %position%. Eres el mejor.
GreatRace.3=%name% al aparato. Gran resultado, P %position%. Pondré el champán a enfriar.
MediocreRace.1=%name% soy %name%. P %position%.Resultado sólido, pero se puede hacer más.
MediocreRace.2=%name% soy %name%. P %position%. No está mal, pero la próxima vez hay que quedar mejor.
CatastrophicRace.1=%name% soy %name% Qué vergüenza. P %position%.
CatastrophicRace.2=%name% soy %name% P %position%. Mejor haberte quedado en casa.
CatastrophicRace.3=%name% soy %name% P %position%. Realmente no ha sido tu día.
Compare2Leader.1=Fuiste de media %relative% %seconds% segundos más lento que el ganador.
Compare2Leader.2=%relative% %seconds% segundos más lento que el ganador de media.
InvalidCritics.1=%conjunction% Simplemente has cometido demasiados errores.
InvalidCritics.2=%conjunction% Demasiados errores, todavía tienes que trabajar en ti mismo.
InvalidCritics.3=%conjunction% La próxima vez comete menos errores.
PositiveSummary.1=En general es bastante bueno.
PositiveSummary.2=En general, puedes estar satisfecho.
PositiveSummary.3=NSin embargo, en general esta muy bien.
GoodPace.1=Eres rápido
GoodPace.2=Tienes un buen ritmo
MediocrePace.1=Necesitas un poco más de velocidad
MediocrePace.2=Puedes ir un poco más rápido
BadPace.1=Aún tienes que trabajar en tu ritmo
BadPace.2=No eres lo suficientemente rápido todavía
GoodConsistency.1=%conjunction% Tienes buena consistencia.
GoodConsistency.2=%conjunction% Conduces de forma muy constante.
MediocreConsistency.1=%conjunction% Se necesita un poco más de consistencia.
MediocreConsistency.2=%conjunction% Podrías conducir un poco más uniformemente.
BadConsistency.1=%conjunction% Necesitas urgentemente trabajar en tu consistencia, la diferencias entre tus tiempos de vuelta es catastrófica.
BadConsistency.2=%conjunction% La diferencia entre tus tiempos de vuelta es muy alta.