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

- Technology can improve tax compliance by improving identification of taxpayers, detection of inconsitencies, and collection capabilities (Okunogbe 2023)
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

- Electronic invoicing creates a new dataset on (emitting) firms' output and (receiving) firms' input

- **Expected effects:** 	&darr; input VAT, = output VAT, &darr; net VAT liability

---

# Setting

- Uruguay is a middle income country in LAC (GDP per cápita ~15K USD)
- VAT is the largest tax liability for firms and the largest source of tax revenue. Evasion of VAT was estimated at 26% (Gomez-Sabaini & Jimenez 2012)
- Mandatory rollout of e-invocing –starting w largest firms– began 2012.

# Approach

- **Main challenge:** Nonrandom buyer-seller pairings, intensity and timing.
- **How I overcome it:** IV strategy (LATE), using network of industry linkages to compute the probability of receiving an e-ticket by industry and year.

<!-- Since emitting firms are v large, there may be less risk of collusion with small players (no individual buyer surpasses 1% of seller turnover) -->
<!-- Also,  -->


---

# Data

- Administrative data on uruguayan firms 2009–2016
  - Monthly summaries of buyer-seller pair transactions
  - VAT affidavits
- Input-output table (2012) for industry linkages
- **Main sample:** Firms with regular (non-simplified) tax filing and not in LTU
- **Outcome variables:** input VAT, output VAT, VAT liabilities
  - Functional form: deflacted + IHS
  - Winsorized at 99th percentile
<!-- - **Covariates:** pre-policy asset and income  deciles, 22 ISIC divisions, firm age quartiles -->
- **Treatment variable:** Tax registered in e-invoices (deflacted  + IHS), N invoices (IHS)
- **Instrumental variable:** Prob. of receiving an e-invoice by industry 

---

### CDF of first emission and share of total output in e-invoices

![h:550](../../out/figures/takeup.share.png)

---

### Network structure and e-invoice roll-out by industry

![h:550](../../out/figures/slides_manual.png)

(gif of e-invoice rollout, or faceted plot per year)

---

# The instrument

Probability of receiving an e-invoice for industry $j$ in time $t$ is equal to the sum of the partial probabilities of recieving an e-invoice from each industry $h$

<br>

$$\text{P(Reception)}_{jt}= \sum_h \underbrace{\frac{\text{Inputs}_{jht}}{\text{Total inputs}_{jt}}}_{\text{Share of }j\text{'s inputs} \text{coming from }h} \cdot\ \text{Share e-invoiced output}_{ht}$$

![bg right:50% w:600](../../out/figures/prob_ticket_reception.by_industry.png)

---

### First stage

![h:500](../../out/tables/first_stage.png)

`F-test (1st stage), IHSeticketTaxK: stat = 8613.9, p < 1e-15` (preferred spec)

---

### Effect of reception of electronic invoices on tax compliance 

![h:550](../../out/tables/iv.png)

---

> **Prefered specification**
> 10% increase in tax in e-invoice $\Rightarrow$ 0.3% increase in VAT liability

# Why the small effect?

- Incomplete implementation of e-invoicing – effective rollout ended last year
- Incomplete coverage of input costs – hard to curtail cost overreporting at this early stage

![bg right w:600](../../out/figures/reception_intensity.all.png)

-----

# Future steps

- Check for heterogeneous results (firm size, ...?)
- Add robustness checks (Chen & Roth 2023)
- Threats to identification? $\text{cov}(Y,Z)\neq0$ 
  - Could happen if sector linkages were related to how much a firm can evade (reasonable concern, may be dampened at aggregate level).
- More disaggregated sectors? (might improve precision)
