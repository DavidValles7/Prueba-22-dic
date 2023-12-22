********************************************************************************
**   		PROGRAMACIÓN PRUEBA ANALISTA -ANALÍTICA PROCOLOMBIA        		  **
**      		ELABORÓ: DAVID ANDRÉS VALLES RESTREPO          				  **
**              			22 de diciembre de 2023							  **
********************************************************************************



*Directorio de trabajo con las bases para facilitar importar y guardar:
clear all
cd "C:\Users\david\OneDrive\Documentos\Proyectos\Prueba ProColombia\prueba22"
set more off

*cargue y merge de bases

import delimited "datos_turistas.txt", delimiter("|") encoding(UTF-8)
save "datos.dta", replace

import excel "Tablas Correlativas.xlsx", sheet("Correlativa municipios") firstrow clear
save "correlativa.dta", replace

rename CODIGO_MUNICIPIO códigomunicipio

merge 1:m códigomunicipio using "datos.dta", force

drop if _merge==1

*Analisis


gen fecha = ym(año, mes) 
format fecha %tm

save "datos_correlativa.dta", replace



collapse (sum) cantidadturistas, by (fecha)
tsset fecha , monthly


tsline cantidadturistas 

ac cantidadturistas 
dfuller cantidadturistas, trend
/*al parecer no hay por que hay tendencia así que se hacen pruebas graficas. 
prueba autocorrelación y prueba de raiz unitaria*/

gen lncantidadturistas =log(cantidadturistas)
dfuller D.lncantidadturistas, trend

/*autocorrelación cae lentamente no hay estacionariedad. entonces se toma las diferencias 
*primera  y segunda diferencia para lograr estacionariedad (t1 - t-1). prueba dicki fuller*/
tsline D.cantidadturistas
dfuller D.cantidadturistas

tsline D2.cantidadturistas
dfuller D2.cantidadturistas


tsline D3.cantidadturistas
dfuller D3.cantidadturistas
*el estadistico es menor al punto critico 5% (p-value:1,02) no hay estacionariedad en la serie ni en el ln


 *::::::::::::::3 PASO -> IDENTIFICAR EL MODELO :::::::::::::::::::::
*se usa prueba de autocorrelación simple  (ac) o parcial (pac)
 *cuantos  a) cuantas medias smoviles y b) auto-regresivo
*autocorelacion de turista con primera  y segunda diferencia, nos dice  el numero de medias moviles

ac D.lncantidadturistas/*0 rezago muy significativo, que esta fuera de las bandas de confianza*/
ac D2.lncantidadturistas/*2 rezago LIGERAMENTE significativo, que esta fuera de las bandas de confianza*/
ac D3.lncantidadturistas /*1 rezago significativo, que esta fuera de las bandas de confianza*/



*autocorelacion parcial nos dice  el numero auto-regresivo

pac D.lncantidadturistas /*0 rezagos significativos, que esta fuera de las bandas de confianza. */
pac D2.lncantidadturistas /*2 rezagos significativos, que esta fuera de las bandas de confianza. es decir proceso autoregresivo de orden 3 */
pac D3.lncantidadturistas /*3 rezagos significativos, que esta fuera de las bandas de confianza. es decir proceso autoregresivo de orden 3 */

*segunda diferencia
*AC -> orden de los MA(2) proceso de medias moviles un rezago
*PAC-> orden de los AR(2) la funcion de autocorrelación parcial mostro que el orden de los rezagos del proceso autoregresivo es de orden 2




*::::::::::::::4 PASO -> ESTIMACIÓN:::::::::::::::::::::

*arima D.Expo_NME, arima(componente autoreg,orden de diferenciación ,componente medias moviles)
*arima D.Expo_NME, arima(AR,I,MA)
*Se hace una combinación
arima D2.lncantidadturistas, arima(2,0,1) /*rezago de MA no es significativo*/
arima D2.lncantidadturistas, arima(2,0,2) /*rezago de MA no es significativo*/
arima D2.lncantidadturistas, arima(1,0,2) /*rezago de MA no es significativo**/

*Tomamos modelo arima D2.lncantidadturistas, arima(2,0,1) 

/*Modelo seleccionado usando la variable normal (primera diferencia se 
especifica en el segundo parametro de la funcion arima)*/
arima lncantidadturistas, arima(2,2,1) 
tsappend, add(16)
predict lncantidadturistas_fut, y dynamic(m(2023m9)) 
tsline lncantidadturistas lncantidadturistas_fut

graph export "Proyeccion de lncantidadturistas.png", as(png) replace

use  "datos_correlativa.dta", clear
