---
marp: true
title: "Nuevas tecnologías y cumplimiento tributario"
author: Guillermo Sánchez Laguardia
theme: default
paginate: true
style: |
    section{
      justify-content: flex-start;
    }
---

<style>
    section.lead {
        text-align: center;
        justify-content: center;
    }
    section::after {
        content: attr(data-marpit-pagination) '/' attr(data-marpit-pagination-total);
    }
    img { max-height: 600px; }
    table {
        height: 100%;
        width: 100%;
        font-size: 20px;
    }
</style>

<!-- _class: lead  -->
<!-- _footer: ""-->
<!-- _paginate: skip  -->

# Nuevas tecnologías y cumplimiento tributario
## La facturación electrónica en Uruguay

Guillermo Sánchez Laguardia
Junio 2024

---

# Motivación

- Los países en desarrollo recaudan menos impuestos que los países desarrollados, limitando su capacidad de implementar políticas y proveer bienes públicos.
- No alcanza con el crecimiento económico para mejorar la recaudación – se necesitan inversiones específicas (Besley & Persson 2013)
- La tecnología puede incrementar la recaudación tributaria a través de mejoras en la identificación de contribuyentes, la detección de inconsistencias y la capacidad de recolección (Okunogbe & Tourek 2024) 
- **Factura electrónica** – Registro digital de cada transacción, con transmisión automática a la autoridad tributaria.

---

![bg right w:650](../../resources/esquema.jpg)

# e-Facturación

- Política implementada en varios países y ha sido efectiva en la reducción del incumplimiento tributario (Bellon et al. 2022, Fan et al. 2023, Eissa et al. 2015)
- En Uruguay: $\uparrow$ 3.7% pagos de IVA (Bérgolo et al. 2017)
- Un aspecto importante de la polííca aún no ha sido evaluado: **efectos indirectos**

<!-- > ℹ️ **Esta tesis**
> Evaluar el efecto de **recibir e-facturas** sobre el cumplmiento tributario -->

<!-- Downstream spillover effects -->

---

> ❓ **Pregunta de investigación**
> ¿Cuál es el efecto de **recibir e-facturas** en el cumplimiento tributario?

<br>

- Me concentro en el **Impuesto al Valor Agregado**, en tanto es el que aparece directamente en los comprobantes electrónicos.
- Impacto de tecnologías en administración pública (Gupta et al. 2017; Lewis-Faupel et al. 2016; Banerjee et al. 2020) 
  - Tecnologías en administración tributaria (Okunogbe y Poulinquen 2022; Okunogbe y Tourek 2024)
- Importancia de **efectos indirectos** para evaluación completa de cualquier intervención pública (Lopez-Luzuriaga & Scartascini 2019)
  - e-facturación genera mucha información nueva – spillovers potencialmente muy importantes

---

# Marco conceptual

La facturación electrónica crea un nuevo registro sobre las ventas de las empresas emisoras y las compras de las empresas receptoras. La DGI puede usar esta información para reducir el **sobre-reporte de compras** de las empresas receptoras:



<br>

![h:350](../../resources/Conceptual.png)

---

# Contexto

- IVA es el impuesto más cuantioso para las empresas y la principal fuente de ingresos tributarios (50% en 2019).
- La evasión de IVA se estimaba en 26% (Gomez-Sabaini & Jimenez 2012)

### La e-facturación en Uruguay

- Implementación de e-facturación empieza en 2011 con un plan piloto, seguida por un período de fuertes incentivos fiscales (2012–2014). 
  - Adhesión obligatoria anunciada en 2015, escalonada por ingresos
- En 2016 habían pocos emisores (~3000) pero por su posicionamiento en la red productiva y su volumen de facturación, una proporción importante de las empresas habían recibido e-facturas para ese entonces.

---

### FDA de la primera emisión y proporción del output en e-facturas

![h:480](../../out/figures/takeup.shareV2.png)

Número reducido de empresas emisoras (6%) con gran pct de output (52% en 2016)

---

## La estrategia

**Desafío principal:** Emparejamiento no aleatorio de compradores y vendedores

**Como lo supero:** DD con tratamiento escalonado, usando la primera recepción de e-facturas como inicio del tratamiento y centrándome en empresas chicas.

![bg left h:650](../../out/figures/takeup_reception.png)

<!-- ![bg right w:600](../../out/figures/small_players.all.png) -->

<!-- Since emitting firms are v large, there may be less risk of collusion with small players (no individual buyer surpasses 1% of seller turnover) -->
<!-- Also,  -->

---

# Datos

- **Fuentes:** Registros administrativos sobre empresas 2009–2016
  - Resumen mensual de transacciones para cada par comprador-vendedor
  - Declaraciones juradas de IVA (2009–2016*)
- **Muestra ppal:** Empresas chicas con regímenes imp. no simplificados (N = 1.8K)
  - No afectan cuando sus proveedores empiezan a emitir e-facturas [[go]](#small-players-back)
- **Variables de resultado:** IVA compras, IVA ventas, IVA adeudado neto (= máx {IVA ventas - IVA compras, 0}) [[go]](#series-crudas-back)
  - Forma funcional: deflactadas + log + winsorizing p99 [[go]](#logs-con-ceros-back)
- **Tratamiento:** Primera recepción de e-factura
- **Grupo de control:** Empresas aún no tratadas y nunca tratadas (25%)
- **Covariables:** Deciles de activos pre-política, 22 secciones CIIU, cuartiles de edad.

---

### Descriptivas de la muestra

![](../../out/tables/sample_summary.png)

---

# Método I: Efecto agregado

Estimo un diseño de diferencias en diferencias con TWFE y tratamiento escalonado

<br>

$$
y_{it} = \beta_{post}\ D_{it} + \alpha_{i} + \tau_{t} + u_{it}
$$

<br>

- $D_{it}$ toma valor uno si la empresa $i$ había recibido alguna e-factura en el período $t$
- $y_{it}$ es el resultado de la empresa $i$ en el año $t$
-  $\alpha_{i}$ y $\tau_{t}$ son efectos fijos de empresa y año

<br>

El impacto total de la política viene dado por el coeficiente $\beta_{post}$, que representa el efecto promedio de recibir e-facturas experimentado por todas las empresas que en algún momento recibieron una.

---

# Método II: Efectos dinámicos

$$
y_{it} = \sum_{l\neq -1, l = -6}^{l = 3} \beta_{l}\cdot \mathbb{1}(R_{it} = l) + \alpha_{i} + \tau_{t} + u_{it}
$$

- $R_{it}$ indica los años desde que la empresa $i$ recibió su primer e-factura
- Excluyo $l = -1$, normalizando los $\beta_l$ a este evento
- Política empieza en 2012 – $\min l = -6$, $\max l = 3$
- Errores estándar clusterizados a nivel de empresa (donde se define el tratamiento)

Los coeficientes $\beta_l$ capturan el efecto de tratamiento dinámico, a $l$ períodos de recibir la primer e-factura.

---

### Efecto de recibir e-facturas sobre cumplimiento tributario (Dinámico)

![h:490](../../out/figures/es.twfe.y.all.png)

Tendencias previas paralelas, post-tratamiento oscila en torno a cero.

---

### Efecto de recibir e-facturas sobre cumplimiento tributario (Agregado)

![h:490](../../out/tables/twfe.y.all.overall_att.all.png)

No hay efectos significativos sobre ninguna variable

---

# Robustez

- Robusto a censurar resultados en p95 (outliers) y a incluir datos de 2016
- Robusto a reestimar con Callaway & Sant'Anna (2021) [[go]](#robustez-callaway--santanna-2021-back)
  - Problemas de estrategia TWFE son menores cuando hay un grupo relevante de nunca-tratados (26%).
- Robusto a cambios en margen extensivo [[go]](#robustez-margen-extensivo-back)


---

### Efecto de recibir e-facturas en el margen extensivo

![h:490](../../out/tables/twfe.y.all.overall_att.ext.png)

Aumenta 1–2% la prob que una empresa reporte IVA compras o IVA ventas

---

# Método III: Efectos heterogéneos

Por el tamaño reducido de la muestra, para ver efectos heterogéneos separo el tratamiento en dos:
 
<br>

$$
y_{it} = \beta_{low}\cdot D_{it} \cdot BelowMedian_{i} + \beta_{high}\cdot D_{it} \cdot AboveMedian_{i} + \alpha_{i} + \tau_{t} + u_{it}
$$

<br>

- $AboveMedian_i$ y $BelowMedian_i$ indican si la empresa $i$ está por encima o por debajo de la mediana en la variable que define grupos heterogéneos.

Comparo $\beta_{low}$ y $\beta_{high}$ para estudiar la existencia de efectos heterogeneos entre los grupos definidos.

---

# Efectos heterogéneos

- **Importaciones.** Solo las empresas locales emiten e-facturas
  - Sectores con alta utilización de insumos importados están menos expuestos
  - No hay efectos [[go]](#dd-het-high-import-industries-back)
- **Consumo final de los hogares.** Mecanismos autorreforzantes del IVA desaparecen (ej: Pomeranz 2015; Naritomi 2019; Wassem 2023)
  - Sectores con alta proporción de ventas a hogares pueden reaccionar más
  - No hay efectos [[go]](#dd-het-high-hh-consumption-industries-back)
- **Tamaño de la empresa** es determinante en las posibilidades de evadir impuestos (ej: Kleven et al. 2016; Alm et al. 2021)
  - Nivel de activos pre-política (a nivel de empresa)
  - Hay efectos en IVA adeudado (ojo con interpretación) [[go]](#dd-het-pre-policy-asset-levels-back)

---

# Método IV: Variables instrumentales

- En Apéndice pruebo estrategia alternativa que me permite incorporar más empresas a la estimación [[go]](#apéndice-b)
  - Computo la probabilidad de recibir una e-factura por año y sector de actividad usando Matriz Insumo-Producto (BCU 2012) y *rollout* de e-facturación
  - Uso la probabilidad de recepción como instrumento del monto de IVA compras que queda registrado en e-facturas (elasticidades)
- En especificación preferida: $\uparrow$ 10% en e-facturas $\Rightarrow$ $\downarrow$ 0.3% IVA compras 
- No hay efectos heterogéneos 

---

# ¿Por qué no hay efecto?

- Implementación incompleta de la política al momento de evaluar – rollout terminó año pasado 
- Cobertura incompleta de costos – dificil reducir sobre-reporte
  - Carrillo et al (2017) – asimetría
- Estrategia puede tener problemas – empresas chicas, panel balanceado
  - IV da resultados similares

![bg right:45% w:550](../../out/figures/reception_intensity_all.png)

---

# Comentarios finales

- En este trabajo, busqué cuantificar el efecto de la recepción de e-facturas sobre el cumplimiento tributario de las empresas uruguayas
- Efectos nulos o muy pequeños – coherentes con período de evaluación + métodos
- Resultado local y de corto plazo – evaluaciones de otros países sugieren mayores efectos en el mediano y largo plazo (Bellon et al. 2022, Fan et al. 2023)
- En el caso de Uruguay – se necesitan datos más recientes

---

<!-- _class: lead -->
<!-- paginate: skip -->

# Apéndice A
## Diferencias en diferencias

---

### Small players [[back]](#datos)

![h:500](../../out/figures/small_players.all.png)

Muestra: ninguna empresa representa más de 1% de las ventas de su proveedor emisor

---

### Series crudas [[back]](#datos)

![h:550](../../out/figures/time_trends.png)

---

### Logs con ceros [[back]](#datos)

Chen y Roth (2023) muestran que las transformaciones cuasi-logarítmicas de variables dependientes no negativas pueden dar lugar a interpretaciones engañosas.

Si hay efectos en el margen extensivo, entonces los efectos estimados  sobre $\log(Y + 1)$ o $\text{arcsinh}(Y)$ dependen de la unidad de medida de $Y$.

Sigo una de sus propuestas: reescalo $Y$ respecto a su valor mínimo $Y_{min}$ y asigno un valor explícito $\epsilon$ a los cambios en el márgen extensivo:

<br>

$$
y_{it} =
\begin{cases}
  \log(\frac{Y_{it}}{Y_{min}}) & \text{si } Y_{it}>0 \\
  -\varepsilon                 & \text{si } Y_{it} = 0
\end{cases}
$$

---

### Robustez: Margen extensivo [[back]](#robustez)

![](../../out/tables/twfe.y.all.overall_att.cr23.png)

---

### Robustez: Callaway & Sant'Anna (2021) [[back]](#robustez)

![h:550](../../out/tables/did.y.all.overall_att.all.png)

---

### DD Het: High import industries [[back]](#efectos-heterogéneos)

![h:550](../../out/tables/twfe.y.all.overall_att.by_imports.png)

---

### DD Het: High HH consumption industries [[back]](#efectos-heterogéneos)

![h:550](../../out/tables/twfe.y.all.overall_att.by_industry.png)

---

### DD Het: Pre-policy asset levels [[back]](#efectos-heterogéneos)

![h:550](../../out/tables/twfe.y.all.overall_att.by_size.png)

---


<!-- _class: lead -->

# Apéndice B
## Variable Instrumental

---

# Alternative approach

![bg right h:600](../../out/figures/industry_graph.png)

IV strategy (LATE), using network of industry linkages to compute the probability of receiving an e-ticket by industry and year.

**Treatment variable:** Tax registered in e-invoices (deflacted  + IHS) 

**Instrumental variable:** Prob. of receiving an e-invoice by industry 

**Main sample:** Firms with regular (non-simplified) tax filing and not under LTU supervision

---

# The instrument

Probability of receiving an e-invoice for industry $j$ in time $t$ is equal to the sum of the partial probabilities of recieving an e-invoice from each industry $h$

<br>

$$\text{P(Reception)}_{jt}= \sum_h \underbrace{\frac{\text{Inputs}_{jh,2012}}{\text{Total inputs}_{j,2012}}}_{\text{Share of }j\text{'s inputs} \text{coming from }h} \cdot\ \text{Share e-invoiced output}_{ht}$$

![bg right:45% w:580](../../out/figures/prob_ticket_reception.by_industry.png)

---

# IV specification

I estimate the following IV spec by 2SLS:

<br>

$$Y_{ijt} = \beta\ R_{ijt} + \mathbf{X}_{ijt}\Gamma + \tau_{t} + \psi_{ij} + \nu_{ijt}$$

$$R_{ijt} = \alpha\ P_{jt} + \mathbf{X}_{ijt}\Gamma + \tau_{t} + \psi_{ij} + \varepsilon_{ijt}$$

- Firms indexed with $i$, time with $t$, industry with $j$
- $R_{ijt}$ is amount of input VAT recorded in e-invoices
- Taking logs in $Y, R$ – $\beta$ is an elasticy
- Firm FE capture time-invariant diff; time FE to capture common shocks.

---

### Effect of e-invoice reception on tax compliance (IV estimates)

![h:500](../../out/tables/iv_short_all.png)

`F-test (1st stage), IHSeticketTaxK: stat = 9173.1, p < 1e-15`

---

## IV Robustness

- Robust to winsorizing at p95 and allowing exits between 2012–2015 [[go]](#iv-alternate-specs-back)
- Alternate instrument: number of e-invoices received – same results [[go]](#iv-alternate-regressor-number-of-e-invoices-back)
- No extensive margin effects [[go]](#iv-extensive-margin-back)
- No heterogeneous effects [[go]](#iv-heterogeneous-effects-back)

<br>

> **Prefered specification**
> 10% increase in tax in e-invoice $\Rightarrow$ 0.3% increase in input VAT

---

### IV: Alternate specs [[back]](#iv-robustness)

![h:550](../../out/tables/iv.y.all.all.png)

---

### IV: Alternate regressor (number of e-invoices) [[back]](#iv-robustness)

![h:550](../../out/tables/iv_short_alt.png)

---

### IV: Extensive margin [[back]](#iv-robustness)

![h:550](../../out/tables/iv.y.ext.png)

---

### IV: Heterogeneous effects [[back]](#iv-robustness)

![h:550](../../out/figures/iv_het.png)
