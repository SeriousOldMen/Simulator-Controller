// Standard
#Include Fragments.es
#Include Choices.es
#Include Conversation.es
#Include Weather.es
[Configuration]
Recognizer=Grammar
[Fragments]
FrontLeft=Delantera Izquierda 
FrontRight=Delantera Derecha
RearLeft=Trasera Izquierda
RearRight=Trasera Derecha
Front=Delante
Rear=Detras
Left=Izquierda
Right=Derecha
All=todas
Suspension=Suspensión
Bodywork=Chasis
Engine=Motor
Temperatures=Temperatura
Pressures=Presión
Wear=desgaste
Cold=frías
Setup=Setup
FuelWarning=avisos de combustible
DamageReporting=avisos de daños
DamageAnalysis=análisis de daños
WeatherUpdate=avisos meteorológicos
PressureReporting=avisos de presión
ForYou=para ti
Increased=Aumentar
Decreased=Reducir
By=en
[Choices]
Announcements=avisos de combustible, avisos de daños, análisis de daños, avisos meteorológicos, avisos de presión
[Listener Grammars]
// Information //
TyrePressures=[(WhatAre) {la presión de los neumaticos, la presión frías de los neumaticos, la presión Setup de los neumaticos, la presión actual, la presión frías, la presión Setup}, (TellMe) la presión {actual, frías, Setup}]
TyreTemperatures=[(WhatAre) la temperatura {de los neumaticos, actual de los neumaticos}, (TellMe) darme la temperatura de los neumaticos]
TyreWear=[{Revisa, Comprueba} {el desgaste de los neumáticos, el desgaste de los neumáticos en este momento}, (TellMe) {el desgaste de los neumáticos, el desgaste de los neumáticos en este momento}]
BrakeTemperatures=[(WhatAre) {las temperaturas de los frenos, las temperaturas actuales de los frenos, las temperaturas de los frenos en este momento}, (TellMe) {las temperaturas de los frenos, las temperaturas actuales de los frenos, las temperaturas de los frenos en este momento}]
BrakeWear=[{Revisa, Comprueba} {el desgaste de los frenos, el desgaste de los frenos en este momento}, (TellMe) {el desgaste de los frenos, el desgaste de los frenos en este momento}]
LapsRemaining=[(TellMe) las vueltas que faltan, Cuantas vueltas quedan, Cuántas vueltas faltan]
FuelRemaining=[Cuanto {deposito, gasolina} queda, cuanto {deposito, gasolina} queda en el tanque, (TellMe) {el deposito que, cuanta gasolina} queda,]
// Pitstop //
PitstopPlan=(CanWe) {planificar la parada, crear un plan para la parada}
DriverSwapPlan=(CanWe) {planificar la cambio de piloto, crear un plan para la cambio de piloto}
PitstopPrepare=(CanWe) {preparar la parada, configurar la parada}
PitstopAdjustFuel=[(CanWe) repostar (Number) {Litros, Galones}, Necesitor repostar (Number) {Litros, Galones}, (CanWe) recargar hasta 10 {Litros, Galones}]
PitstopAdjustCompound=[(CanWe) {usar, cambiar a} neumaticos secos, Podemos {usar, cambiar a} neumaticos de lluvia, Podemos {usar, cambiar a} neumaticos intermedio]
PitstopAdjustPressureUp=[(CanWe) incrementa {en la rueda delantera izquierda, en la rueda delantera derecha, en la rueda trasera izquierda, en la rueda trasera derecha, en todas las ruedas} con (Digit) {punto, coma} (Digit), (Digit) {punto, coma} (Digit) más de presión {en la rueda delantera izquierda, en la rueda delantera derecha, en la rueda trasera izquierda, en la rueda trasera derecha, en todas las ruedas}]
PitstopAdjustPressureDown=[(CanWe) disminuye {en la rueda delantera izquierda, en la rueda delantera derecha, en la rueda trasera izquierda, en la rueda trasera derecha, en todas las ruedas} con (Digit) {punto, coma} (Digit), (Digit) {punto, coma} (Digit) menos de presión {en la rueda delantera izquierda, en la rueda delantera derecha, en la rueda trasera izquierda, en la rueda trasera derecha, en todas las ruedas}]
PitstopNoPressureChange=[(CanWe) dejar la {presión de los neumáticos, la presión} sin cambios, (CanWe) dejar la {presión de los neumáticos, presión} como está, (CanWe) dejar las {presiones de los neumáticos, presiones} sin cambios, (CanWe) {dejar, mantener} las {presiones de los neumáticos, presiones} como están]
PitstopNoTyreChange=[(CanWe) {dejar, mantener} los neumáticos en el coche, no cambiar los neumáticos, (CanWe) {dejar, mantener} los neumáticos]
PitstopAdjustRepairSuspension=[(CanWe) repare la suspensión, no reparar la suspensión]
PitstopAdjustRepairBodyWork=[(CanWe) reparar el chasis, no reparar el chasis]
PitstopAdjustRepairEngine=[(CanWe) repare el motor, no reparar el motor]
PitstopCompensatePressureLoss=[(CanWe) compensar la pérdida de {presión, presión de los neumáticos, presión por favor, presión de los neumáticos por favor}, Compense la pérdida de {presión, presión de los neumáticos, presión por favor, presión de los neumáticos por favor}, {Tenga, Tener} en cuenta la pérdida de {presión, presión de los neumáticos}]
PitstopNoCompensatePressureLoss=[{Por favor no, No} compensar la pérdida de {presión, presión de los neumáticos, presión por favor, presión de los neumáticos por favor}, No más compensación por la pérdida de {presión, presión de los neumáticos, presión por favor, presión de los neumáticos por favor}]
[Speaker Phrases]
// Conversation //
GreetingEngineer.1=Hola %driver%, soy %name%, Me ocuparé de tu coche hoy.
GreetingEngineer.2=Soy %name%. Estare pendiente de tu coche en esta sesión.
GreetingEngineer.3=Me llamo %name%.
GreetingStrategist.1=%strategist% también está aquí.
GreetingStrategist.2=Y tendrás el apoyo de nuestro estratega %strategist%.
GreetingStrategist.3=Nuestra estratega de la carrera %strategist% también está aquí.
CallUs.1=Llámenos si tiene preguntas. 
CallUs.2=Puede llamarnos cuando quiera.
CallUs.3=Y ahora buena suerte.
CallMe.1=Puedes llamarme si tienes preguntas. Buena suerte.
CallMe.2=Llámeme cuando quiera.
CallMe.3=Y ahora buena suerte.
Later.1=Lo siento, todavía no tengo suficientes datos. Por favor, pregunta en una o dos vueltas.
Later.2=Tenemos una muerte azul. Windows XP es una mierda. Dame un minuto.
Later.3=Tus datos de telemetría se corrompieron en esta vuelta. Necesitamos otra vuelta para recoger los datos.
MoreChanges.1=¿tienes más cambios?
MoreChanges.2=¿Alguna otra cosa?
MoreChanges.3=¿Hay algo más que deba cambiar?
// Announcement Handling //
ConfirmAnnouncementOff.1=No quieres más %announcement%, verdad?
ConfirmAnnouncementOff.2=Nada de %announcement%?
ConfirmAnnouncementOn.1=¿Quieres que te dé %announcement%?
ConfirmAnnouncementOn.2=Te daré %announcement%.
// Information //
Laps.1=Aún tienes %laps% vueltas para finalizar.
Laps.2=Tienes combustible para %laps% vueltas.
LowLaps.1=Te quedarás sin combustible en %laps% vueltas.
LowLaps.2=Te queda para %laps% vueltas. Deberiamos prerar la parada en la siguiente vuelta.
LapsAlready.1=Ya has conducido %laps% vueltas.
LapsAlready.2=%laps% vueltas ya están detrás de ti.
LapsFuel.1=Tienes combustible para otras %laps% vueltas.
LapsFuel.2=El combustible restante es bueno para %laps% vueltas.
LapsStint.1=El stint terminara en %laps% vueltas.
LapsStint.2=Te queda %laps% vueltas para terminar el stint.
LapsSession.1=La sesión finalizara en %laps% vueltas.
LapsSession.2=Solo quedan %laps% vueltas para terminar la sesión.
Fuel.1=Todavía tienes %fuel% %unit% en el deposito.
Fuel.2=Te quedan %fuel% %unit%.
Fuel.3=%fuel% %unit% restantes.
Pressures.1=Bien, las presiones %type% son.
Pressures.2=El ordenador nos muestra las siguientes presiones %type%.
Pressures.3=Las presiones %type% son.
Temperatures.1=Bien, aquí están las temperaturas.
Temperatures.2=Tenemos las siguientes temperaturas.
Temperatures.3=Las temperaturas actuales son.
TyreFL.1=%delta% Delantera izquierda %by% %value%.
TyreFL.2=%delta% %by% %value% %unit% en la rueda delantera izquierda
TyreFL.3=%delta% %by% %value% %unit% marca el neumatico delantero izquierdo.
TyreFR.1=%delta% Delantera derecha %by% %value%.
TyreFR.2=%delta% %by% %value% %unit% en la rueda delantera derecha
TyreFR.3=%delta% %by% %value% %unit% marca el neumatico delantero izquierdo.
TyreRL.1=%delta% Trasera izquierda %by% %value%.
TyreRL.2=%delta% %by% %value% %unit% en la rueda trasera izquierda.
TyreRL.3=%delta% %by% %value% %unit% marca el neumatico trasero izquierdo.
TyreRR.1=%delta% Trasera derecha %by% %value%.
TyreRR.2=%delta% %by% %value% %unit% en la rueda trasera derecha.
TyreRR.3=%delta% %by% %value% %unit% marca el neumatico trasero derecho.
BrakeFL.1=Delantero izquierdo %value%.
BrakeFL.2=%value% %unit% en el freno Delantero izquierdo
BrakeFL.3=%value% %unit% marca el disco Delantero izquierdo
BrakeFR.1=Delantero derecho %value%.
BrakeFR.2=%value% %unit% en el freno Delantero derecho
BrakeFR.3=%value% %unit% marca el disco Delantero derecho.
BrakeRL.1=Trasero izquierdo %value%.
BrakeRL.2=%value% %unit% en el freno trasero izquierdo.
BrakeRL.3=%value% %unit% en el disco trasero izquierdo.
BrakeRR.1=Trasero derecho %value%.
BrakeRR.2=%value% %unit% en el freno trasero derecho.
BrakeRR.3=%value% %unit% marca el disco trasero derecho.
Wear.1=Bien, estos son los datos.
Wear.2=Los analisis marcan los siguientes desgastes.
Wear.3=El desgaste actual es.
NoData.1=No tengo datos.
NoData.2=¿Es una broma? No tengo datos.
WearFL.1=El neumatico delantero izquierdo todavia tiene un %remaining% por ciento.
WearFL.2=La rueda Delantera izquierda tiene un desgaste del %used% por ciento.
WearFL.3=Nos queda un %used% porciento en la rueda delantera izquierda.
WearFR.1=Delantera derecha todavia tiene un %remaining% por ciento.
WearFR.2=El neumatico delantero derecho tiene un desgaste del %used% por ciento.
WearFR.3=Nos queda un %used% porciento en la rueda delantera derecha.
WearRL.1=El neumatico trasero izquierdo todavia tiene un %remaining% por ciento.
WearRL.2=La rueda trasera izquierda tiene un desgaste del %used% por ciento.
WearRL.3=Nos queda un %used% porciento en la rueda trasera izquierda.
WearRR.1=El neumatico trasero derecho todavia tiene un %remaining% por ciento.
WearRR.2=La rueda trasera derecha tiene un desgaste del %used% por ciento.
WearRR.3=Nos queda un %used% porciento en la rueda trasera derecha.
// Fuel Warning //
LowFuel.1=Soy %name%. Tienes gasolina para %laps% vueltas. Échale un ojo a eso.
LowFuel.2=%driver% soy %name%. El combustible se está acabando, sólo tienes para %laps% vueltas.
VeryLowFuel.1=Cuidado. En %laps% vueltas te quedaras sin gasolina.
VeryLowFuel.2=¿Te funciona el control de gasolina? Te estás quedando sin combustible.
VeryLowFuel.3=Advertencia. Te quedarás sin combustible en%laps% vueltas.
// Damage Warning & Anakysis //
SuspensionDamage.1=%driver% soy %name%. Has tenido un accidente y la suspensión se ha visto afectada.
SuspensionDamage.2=Los datos de la suspensión muestran algunos daños después de tu último accidente.
SuspensionDamage.3=%driver% soy %name%. Nuestros datos muestran problemas con la suspensión.
BodyworkDamage.1=%driver% soy %name%. La aerodinámica se dañó durante tu último accidente.
BodyworkDamage.2=Parece que el chasis y la aerodinámica estan dañadas.
BodyworkDamage.3=%driver% soy %name%. Puedo ver en los datos que el chasis ha sido dañado.
EngineDamage.1=%driver% soy %name%. Tienes problemas en el motor.
EngineDamage.2=Parece que el motor pierde potencia.
EngineDamage.3=%driver% soy %name%. Puedo ver en los datos que el motor tiene un problema.
BothDamage.1=%driver% soy %name%. Tienes daños graves. Los datos muestran problemas con la suspensión y la carrocería.
BothDamage.2=En tu último accidente, tanto la aerodinámica como la suspensión se vieron afectadas.
BothDamage.3=%driver% soy %name%. Nuestros datos muestran daños en el chasis y también en la suspensión.
AllDamage.1=Eso fue un accidente. El motor está dañado y el resto no pinta nada bien.
AllDamage.2=%driver% soy %name%. Tienes daños severos, incluso el motor tiene un problema.
DamageAnalysis.1=Lo investigaré y volveré a hablar contigo.
DamageAnalysis.2=Voy a hacer un análisis lo más rápido posible.
DamageAnalysis.3=Tal vez necesitemos algunas reparaciones. Déjame recoger algunos datos.
NoDamageAnalysis.1=Analizar tus tiempos de vuelta o incluso una reparación ya no tiene sentido.
NoDamageAnalysis.2=Ahora debemos evitar las reparaciones a toda costa.
RepairPitstop.1=%driver%, He terminado el análisis. Estás perdiendo %delta% segundos en cada vuelta. Recomiendo una parada en boxes para reparar.
RepairPitstop.2=%driver% soy %name%. Perderás  %delta% segundos por vuelta en las %laps% vueltas restantes. Creo que deberías  venir a reparar.
RepairPitstop.3=%driver%, los daños son demasiado altos para las %laps% restantes. Deberías venir a reparar
NoRepairPitstop.1=%driver%, He terminado el análisis. Estás perdiendo %delta% segundos, pero lo dejaremos así por ahora.
NoRepairPitstop.2=%driver% soy %name%. Estás perdiendo %delta% segundos por vuelta, pero una reparación no vale la pena en este momento.
NoRepairPitstop.3=%driver%, parece que el daño no nos esta afectando por el momento.
NoTimeLost.1=%driver%, He terminado el análisis. No pierdes nada de tiempo.
NoTimeLost.2=%driver% soy %name%. Parece que el daño no nos esta afectando por el momento.
NoTimeLost.3=%driver%, no tenemos daños. Lo estás haciendo muy bien.
// Pressure Loss Warning //
PressureLoss.1=Parece que su neumático %tyre% está perdiendo presión. Voy a echar un vistazo a eso.
PressureLoss.2=Tu neumático %tyre% ha perdido presión, ten cuidado.
PressureLoss.3=Hola %driver%, puedo ver en los datos que tu neumático %tyre% está perdiendo presión. Déjame ver qué podemos hacer.
// Pitstop Planning, Preparation & Handling //
NoPitstop.1=No necesitamos hacer eso. Sólo entra.
NoDriverSwap.1=Lo siento, estás solo hoy.
NoDriverSwap.2=No hay ningún otro piloto en este momento.
NoPitstop.2=Esto no tiene sentido. Puedes entrar cuando quieras.
MissingPlan.1=Lo siento, aún no he planeado una parada en boxes.
MissingPlan.2=Oh, parece que tenemos que actualizar el plan de paradas en boxes.
ConfirmPlan.1=¿Planifico ya una parada en boxes %forYou%?
ConfirmPlan.2=Deberíamos prepararnos para una parada en boxes %forYou%, ¿de acuerdo?
ConfirmRePlan.1=Ya tenemos un plan para la próxima parada. ¿Debo crear uno nuevo?
ConfirmRePlan.2=Ya tenemos un plan o ¿quieres que cree uno nuevo?
ConfirmPrepare.1=¿Aviso al equipo de boxes?
ConfirmPrepare.2=¿El equipo debe preparar la parada en boxes?
ConfirmPrepare.3=Si te parece bien, dejaré que el equipo de boxes se prepare.
PitstopLap.1=Puedes entrar en boxes en la vuelta %lap%.
PitstopLap.1=Bien, el equipo estará listo en la vuelta %lap%.
PrepareLap.1=Bien, dejaré que el equipo prepare la parada en boxes para la vuelta %lap%.
PrepareLap.2=El equipo estará listo para la vuelta %lap%.
PrepareLap.3=Vamos a preparar todo para la vuelta %lap%.
PrepareNow.1=Bien, dejaré que el equipo prepare todo inmediatamente.
PrepareNow.2=Estaremos listos cuando tú lo estés.
ComeIn.1=Puedes entrar en las siguientes vueltas.
ComeIn.2=Puedes entrar cuando estés preparado.
LowComeIn.1=Deberías entrar lo antes posible.
LowComeIn.2=Deberías entrar inmediatamente.
CallToPit.1=Puedes venir a hacer una parada.
CallToPit.2=Estamos casi listos. Ya puedes entrar.
CallToPit.3=Estamos listos para la parada en boxes. El equipo te está esperando.
CallToPit.4=El equipo está casi listo. Entra.
Perform.1=Bien, deja que la tripulación haga su trabajo. Comprueba el encendido, relájate y prepárate para volver a arrancar el motor.
Perform.2=Mantenga los frenos, compruebe el encendido y prepárese para volver a arrancar.
Pitstop.1=%driver%, tenemos lo siguiente para la parada numero %number%.
Pitstop.2=%driver% soy %name%. Recomiendo esto para la parada en boxes número %number%.
Pitstop.3=%driver% soy %name%. La parada numero %number% es la siguiente.
NoRefuel.1=No es necesario repostar.
NoRefuelLap.1=No es necesario repostar.
NoRefuelLap.2=Tienes suficiente combustible para el resto de la sesión.
NoRefuelLap.3=No hace falta más combustible.
Refuel.1=Tenemos que repostar %fuel% %unit%.
Refuel.2=%fuel% %unit% necesita repostar.
Refuel.3=%fuel% %unit% serán suficientes.
RefuelAdjusted.1=He corregido la cantidad de combustible para el último stint.
RefuelAdjusted.2=Para el último stint he ajustado la cantidad de combustible.
DryTyres.1=Utilizaremos neumáticos  %compound% y el número de juego %set%.
DryTyres.2=Los neumáticos %compound% serán los mejores. El juego %set%  está como nuevo.
DryTyres.3=Los neumáticos  %compound% son nuestra elección.
DryTyresNoSet.1=Utilizaremos neumáticos %compound%.
DryTyresNoSet.2=Los neumáticos %compound% serán lo mejor.
DryTyresNoSet.3=Los neumáticos %compound% son nuestra elección.
WetTyres.1=Los neumáticos %compound% serán los mejores.
WetTyres.2=Montaremos los neumáticos %compound%.
WetTyresNoSet.1=Los neumáticos %compound% serán los mejores.
WetTyresNoSet.2=ontaremos los neumáticos %compound%.
NewPressures.1=Las presiones corregidas son.
NewPressures.2=Tenemos algunos cambios para las presiones.
PressureCorrectionUp.1=Hemos aumentado las presiones para el próximo stint en %value% %unit% porque las temperaturas están bajando.
PressureCorrectionUp.2=Como las temperaturas están bajando, hemos aumentado las presiones en%value% %unit% para el próximo stint.
PressureCorrectionDown.1=Hemos disminuido las presiones para el próximo stint en %value% %unit% porque las temperaturas están subiendo.
PressureCorrectionDown.2=Como las temperaturas están subiendo, hemos disminuido las presiones en %value% %unit%  para el próximo stint.
PressureAdjustment.1=Hemos compensado la pérdida de presión en el neumático %tyre%.
PressureAdjustment.2=Se tuvo en cuenta la pérdida de presión en el neumático %tyre%.
NoTyreChange.1=No cambiamos los neumaticos.
NoTyreChange.2=los neumáticos no son cambiados.
NoTyreChangeLap.1=Un cambio de neumáticos ya no tiene sentido para el tiempo que queda.
NoTyreChangeLap.2=No vamos a cambiar los neumáticos tan tarde.
RepairSuspension.1=Hay que reparar la suspensión.
RepairSuspension.2=La suspensión debería ser reparada.
RepairSuspension.3=Reparamos la suspensión.
NoRepairSuspension.1=La suspensión parece estar bien.
NoRepairSuspension.2=La suspensión está bien.
NoRepairSuspension.3=No se necesita reparar la suspensión.
RepairBodywork.1=Tenemos que arreglar el difusor.
RepairBodywork.2=El chasis y la aerodinámica deben ser reparadas.
RepairBodywork.3=Vamos a reparar la aerodinámica.
NoRepairBodywork.1=El chasis y la aerodinámica no necesita reparación.
NoRepairBodywork.2=La aerodinámica no tiene ningún daño.
NoRepairBodywork.3=No hay que reparar la carrocería.
RepairEngine.1=Vamos a reparar el motor.
RepairEngine.2=El motor necesita algunas reparaciones.
NoRepairEngine.1=El motor está bien.
NoRepairEngine.2=El motor no necesita reparación.
ConfirmFuelChange.1=Bien, repostaremos %fuel% %unit%, ¿es correcto?.
ConfirmFuelChange.2=Quieres repostar %fuel% %unit%, ¿verdad?
ConfirmCompoundChange.1=Bien, cambiaremos a neumáticos %compound%, ¿es correcto?
ConfirmCompoundChange.2=Me pides que cambie a neumáticos%compound% en la próxima parada en boxes, ¿verdad?
CompoundNotAvailable.1=No disponemos de este compuesto de neumático.
CompoundNotAvailable.2=Los neumáticos %compound% no están disponibles para esta carrera.
CompoundNotAvailable.3=Aquí no tenemos neumáticos %compound%.
ConfirmPressureChange.1=La presión del neumático %tyre% será %action% por %delta% %unit%, ¿es correcto?
ConfirmPressureChange.2=Me pides que %action% la presión del neumatico %tyre% en %delta% %unit% en la próxima parada en boxes, ¿verdad?
ConfirmAllPressureChange.1=La presión de todos los neumáticos será %action% por %delta% %unit%, ¿es correcto?
ConfirmAllPressureChange.2=Me pides que %action% la presión de todos los neumáticos en %delta% %unit% en la próxima parada en boxes, ¿verdad?
ConfirmNoPressureChange.1=Bien, dejaremos las presiones de los neumáticos como están, ¿es correcto?
ConfirmNoPressureChange.2=Me pides que no cambie la presión de los neumáticos en la próxima parada en boxes, ¿verdad?
ConfirmNoTyreChange.1=Bien, no vamos a cambiar los neumáticos, ¿es así?
ConfirmNoTyreChange.2=Se supone que debemos dejar los neumáticos puestos, ¿no?
ConfirmRepairChange.1=De acuerdo, vamos a %negation% reparar el %damage%, ¿es correcto?
ConfirmRepairChange.2=Me pides que  %negation% repare el %damage% durante la próxima parada en boxes, ¿verdad?
ConfirmPlanUpdate.1=De acuerdo, he cambiado todo segun tus ordenes.
ConfirmPlanUpdate.2=He actualizado el plan de paradas como has dicho.
ConfirmPlanUpdate.3=El equipo está informado de tu cambio.
// Data Update Handling //
ConfirmDataUpdate.1=Algo más. ¿Como te sentistes con el coche? ¿Agregamos la configuración a nuestra base de datos?
ConfirmDataUpdate.2=Ah, sí, ¿los ajustes estaban bien? Entonces los añadiré a nuestra base de datos.
DataUpdated.1=Todo anotado. Tomaremos una cerveza esta noche.
DataUpdated.2=Bien, hecho. Hasta luego.