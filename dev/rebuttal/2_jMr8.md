# Reviewer 2 (jMr8, rating: 6 `weak accept')

We thank the reviewer very much for their thoughtful review. 

## Sec 2.1 - Limitations of Inverse Problem

The reviewer pointed out that the "inverse problem is ill-conditioned and could not recover the perfect signal in theory." The authors agree that this can indeed be seen as a form of inverse problem and common caveats such as non-uniqueness and instability apply ([Haltmeier and Nguyen, 2020](https://arxiv.org/abs/2006.03972)). We use $\ell^2$-regularization for the linear probe (ridge regression), which corresponds to Tikhonov regularization in the context of approximation theory ([Björkström, 2001](https://www2.math.su.se/matstat/reports/seriea/2000/rep5/report.pdf)). We confess that we did not carefully consider the parameter choice for the ridge penalty, nor has this been carefully studied in the broader literature on linear probes for mechanistic interpretability to the best of our knowledge. 

Indeed we would expect that the signal would not perfectly be recovered in theory given the compression of the data. However, some signal would indeed imperfectly be recovered, with a closer approximation of perfection in recovery the 'better' the model is. Given that LLMs are essentially compressing textual information, and that LLMs have demonstrated a high capability of doing so, we expect an inverse attempt to recover the signal to be partially successful. What is not to be expected is an interpretation that this imperfect yet-close-enough-to-accurate signal recovery is interpreted as the system having a 'mental model' of the earth, and thus showing 'sparks' of general intelligence - especially when 'general intelligence' and even 'intelligence' are narrowly defined in this space, and when there are ideal conditions for misinterpretation of results in the form of anthropomorphism and cognitive bias. 

Thus, we still think that this simple experiment in Section 2.1 describes the problem of running linear probes on LLMs reasonably well at a high level. If anything, the challenges pointed out by the reviewer therefore cast further doubt on this practice. We will add a note or paragraph on this in the final manuscript. Furthermore, we would like to point out that even in the case of imperfect yet-close-enough-to-accurate signal recovery, this is not to be interpreted as the system having a 'mental model' of the earth, and thus showing 'sparks' of general intelligence - especially when 'general intelligence' and even 'intelligence' are narrowly defined in this space, and when there are ideal conditions for misinterpretation of results in the form of anthropomorphism and cognitive bias.

## Sec 2.3.2. - The Parrot Test

> "The objective aims to evaluate the stochastic parrot in RoBERTa, right?"

Correct. In Section 2.3.2. we apply a 'strong' test to the hypothesis that LLMs 'understand'. We provide additional details in Appendix B. 

> "While I agree this could be a good way to evaluate the learned representation, is this a spurious correlation?"

We show results that one might interpret as the models having some understanding of economics, and being able to imperfectly forecast economic indicators. The 'spurious' correlation is then in the interpretation that the 'accuracy' of the output of the model correlating with economic indicators is a cue that the model is understanding - or more specifically that the correlation between the output of the model and the 'ground truth' economic indicators is 'caused' by the model's understanding of the text. We then show that the model fails to 'understand' when we apply a simple linguistic transformation to our experiment. 

