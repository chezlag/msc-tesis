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

# Conceptual framework

> ❓ **Research question**
>
> What is the effect of receiving e-invoices on tax compliance?

<br>

- Firms can underpay VAT by underreporting sales and/or overreporting costs

- Electronic invoicing creates a new dataset on (emitting) firms' output and (receiving) firms' input

- **Expected effects:** 	&darr; input VAT, = output VAT, &darr; net VAT liability

---

# Setting

- Uruguay is a middle income country in LAC (GDP per cápita ~15K USD)
- VAT is the largest tax liability for firms and the largest source of tax revenue. Evasion of VAT was estimated at 26% (Gomez-Sabaini & Jimenez 2012)
- Mandatory rollout of e-invocing –starting w largest firms– began 2012

# Approach

- **Main challenge:** Causal identification is tricky – non-random buyer-seller pairings
- **How I overcome it:** Event study-type regression (Callaway & Sant'Anna 2021), using the  quasi-experimental variation of **first e-invoice reception**, focusing on small firms.
<!-- Since emitting firms are v large, there may be less risk of collusion with small players (no individual buyer surpasses 1% of seller turnover) -->
<!-- Also,  -->


---

# Data

- Administrative data on uruguayan firms 2010–2015 (incomplete implementation)
  - Monthly summaries of buyer-seller pair transactions
  - VAT affidavits
- **Main sample:** Small firms excl. simplified VAT filing (N bal = 8610, ~15% of firms)
- **Outcome variables:** input VAT, output VAT, VAT liabilities
  - Functional form: Log w Chen & Roth (2023) extensive margin @ 10%
  - Winsorized at 99th percentile
- **Covariates:** pre-policy asset and income  deciles, 22 ISIC divisions, firm age quartiles
- **Treatment variable:** Date of first e-invoice
- **Control group:** Not-yet-treated firms

---

### CDF of first emission and first reception date

![h:550](../../out/figures/takeup.full.png)

---

### Treatment effect on tax compliance of first e-invoice reception 

![h:550](../../out/figures/es.did.y.all.S4_bal_ctrl_p99_nytInf.png)

---

### Treatment effect on tax compliance of first e-invoice reception 

![h:550](../../out/tables/did.y.all.overall_att_all.png)

---

# Why no effect?

- Incomplete implementation of e-invoicing (rollout ended in 2020)

- Incomplete coverage of input costs – hard to curtail cost overreporting

![h:350](../../out/figures/reception_intensity.all.png)

-----

# Limitations

- Reduced time period (can't see full effect of the reform)
- Small firms only

# Future steps

- Check for heterogeneous results by firm size and industry
- Add robustness checks (change extensive margin responses)

---

### Buyers' share of e-invoice emitting sellers' income

![h:550](../../out/figures/small_players.all.png)

---

### Raw series

![h:550](../../out/figures/time_trends.png)
