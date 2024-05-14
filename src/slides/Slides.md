---
marp: true
title: "New technologies and firm tax compliance. Electronic invocing in Uruguay."
author: Guillermo Sánchez Laguardia
theme: default
paginate: false
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

# New technologies and firm tax compliance
## Electronic invoicing in Uruguay

Guillermo Sánchez Laguardia
April 2024

---

# Motivation

- Technology can improve tax compliance by improving identification of taxpayers, detection of inconsistencies, and collection capabilities (Okunogbe 2023)
- **Electronic invoicing** – Digital record of every transaction with automatic transmission to tax authority
- Widely implemented policy, has been shown to reduce noncompliance in middle and low income countries alike
- One important feature of the policy has not been evaluated: **spillovers**


> ℹ️ **This dissertation**
> Evaluate the effect of **receiving e-invoices** on tax compliance (i.e. of  having a trading partner that starts emmiting e-invoices)

<!-- Downstream spillover effects -->

---

> ❓ **Research question**
>
> What is the effect of receiving e-invoices on tax compliance?


# Conceptual framework

Electronic invoicing creates a new dataset on (emitting) firms' output and (receiving) firms' input. For receiving firms I expect:

<br>

![h:180](../../resources/ConceptDiagram.png)

---

# Setting

- Uruguay is a middle income country in LAC (GDP per cápita ~15K USD)
- VAT is the largest tax liability for firms and the largest source of tax revenue. Evasion of VAT was estimated at 26% (Gomez-Sabaini & Jimenez 2012)
- Mandatory rollout of e-invocing –starting w largest firms– began 2012.

# Approach

- **Main challenge:** Nonrandom buyer-seller pairings
- **How I overcome it:** Staggered DD, using time of first e-invoice reception and focusing on small firms.

<!-- Since emitting firms are v large, there may be less risk of collusion with small players (no individual buyer surpasses 1% of seller turnover) -->
<!-- Also,  -->


---

# Data

- Administrative data on uruguayan firms 2009–2016
  - Monthly summaries of buyer-seller pair transactions
  - VAT affidavits
- **Main sample:** Small firms with non-simplified tax regimes (N = 1.8K)
- **Outcome variables:** input VAT, output VAT, net VAT liability
  - Functional form: deflacted + IHS + winsorized p99
- **Treatment variable:** Year of first e-invoice reception
- **Control group:** Not-yet-treated firms
- **Covariates:** pre-policy asset and income  deciles, 22 ISIC sections, firm age quartiles

---

### CDF of first emission and share of total output in e-invoices

![h:480](../../out/figures/takeup.shareV2.png)

Small number of emitting firms (6%) with large share of output (52% in 2016)

---

### Effect of e-invoice reception on tax compliance (Dynamic)

![h:490](../../out/figures/es.twfe.y.all.png)

---

### Effect of e-invoice reception on tax compliance (Overall)

![h:490](../../out/tables/twfe.y.all.overall_att.all.png)

No sig effect on any variable (signs are irrelevant?)

---

## DD Robustness

- Robust to winsorizing at p95 and including 2016 data
- Robust to reestimating with Callaway & Sant'Anna (2021) [[go]](#robustness-callaway--santanna-2021-back)
- Small effects on extensive margin, dissapear w CS21

## DD Heterogeneity

- Sectors w high exposure to imports – no effect [[go]](#dd-het-high-import-industries-back)
- Sectors w high share of household consumption – no effect [[go]](#dd-het-high-hh-consumption-industries-back)
- High/low pre-policy assets – v strong effect (prob unreliable) [[go]](#dd-het-pre-policy-asset-levels-back)

---

<!-- _class: lead -->

# IV

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

---

> **Prefered specification**
> 10% increase in tax in e-invoice $\Rightarrow$ 0.3% increase in input VAT

# Why the small effect?

- Incomplete implementation of e-invoicing – effective rollout ended last year
- Incomplete coverage of input costs – hard to curtail cost overreporting at this early stage

![bg right w:600](../../out/figures/reception_intensity_all.png)

---

# Closing remarks

- Small effect is reasonable considering state of the policy at time of evaluation
- Promising results w alternate specification

## Future steps

- To do it right – get more data
- Validate IV strategy – Error autorcorrelation?
- Threats to identification? $\text{cov}(Y,Z)\neq0$ 
  - Could happen if sector linkages were related to how much a firm can evade (reasonable concern, may be dampened at aggregate level).

---

<!-- _class: lead -->

# Appendix

---

### Robustness: Callaway & Sant'Anna (2021) [[back]](#dd-heterogeneity)

![h:550](../../out/tables/did.y.all.overall_att.all.png)

---

### DD Het: High import industries [[back]](#dd-heterogeneity)

![h:550](../../out/tables/twfe.y.all.overall_att.by_imports.png)


---

### DD Het: High HH consumption industries [[back]](#dd-heterogeneity)

![h:550](../../out/tables/twfe.y.all.overall_att.by_industry.png)

---

### DD Het: Pre-policy asset levels [[back]](#dd-heterogeneity)

![h:550](../../out/tables/twfe.y.all.overall_att.by_size.png)

---

### IV: Alternate specs [[back]](#iv-robustness)

![h:550](../../out/tables/iv.y.all.all.png)

---

### IV: Alternate regressor (number of e-invoices) [[back]](#iv-robustness)

![h:550](../../out/tables/iv_short_alt.png)

---

### IV: Extensive margin [[back]](#iv-robustness)

![h:550](../../out/tables/iv.y.ext.png)
