## Inverse Problem

The reviewer points out that the "inverse problem is ill-conditioned and could not recover the perfect signal in theory." We agree that this (and indeed the practice of probing LLMs that have seen vast amounts of data) can be seen as a form of inverse problem and common caveats such as non-uniqueness and instability apply ([Haltmeier and Nguyen, 2020](https://arxiv.org/abs/2006.03972)). We use $\ell^2$-regularization for the linear probe (ridge regression), which corresponds to Tikhonov regularization in the context of approximation theory ([Björkström, 2001](https://www2.math.su.se/matstat/reports/seriea/2000/rep5/report.pdf)). We confess that we did not carefully consider the parameter choice for the ridge penalty, nor has this been carefully studied in the referenced literature to the best of our knowledge (casting further doubt on this practice). We will add a note or paragraph on this in the final manuscript.

## The Parrot Test

The 'spurious' correlation is in the interpretation that the correlation between the output of the model and the 'ground truth' economic indicators is 'caused' by the model's understanding of the text. We show that the model fails to 'understand' when we attack it with nonsense prompts.

## Anthropomorphism and AI

Reflecting on your comment, we think there are at least 3 ways to reach a better understanding:

- Acknowledgement: researchers should consider acknowledging our tendency to anthropomorphize either in a dedicated ‘limitations’ section or when discussing results.
- Stronger testing: researchers should refrain from drawing premature conclusions about AGI, unless these conclusions are based on strong hypothesis tests.
- Epistemologically robust standards: we call for more precise definitions of terms like ‘intelligence’ and ‘AGI’, and iterations over how we will measure them

We will attempt to summarize our position in the main body or the appendix.

## Other Modalities

The concerns we have raised may apply to many applications but are urgent in the context of LLMs. Many people attribute our ability to understand, to our ability to communicate through language. We can certainly imagine there is some degree of anthropomorphizing with any sufficiently powerful ‘AI’ technology. But as language is an all too obvious feature distinguishing us from other species, it is not surprising that LLMs have so far been anthropomorphized more so than foundation models with other modalities.
