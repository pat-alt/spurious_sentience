# Reviewer D4ep

We thank the reviewer for the detailed and thoughtful review. 

## Lack of distinct prescription

The main weakness pointed out by the reviewer is that the paper '[...] lacks a distinct prescription beyond a call for AI researchers to be more cautious [...]'. We fall short of doing so in the paper mostly for reasons of scope and scale. Where possible we will add a paragraph either in the body, which is limited by the page limit, or the appendix. In the meantime, we try to answer your specific questions below:

> " [...] if we assume that tearing down the whole publishing incentive structure is beyond the pale, what distinct steps can researchers actually take when experimenting, writing, reviewing and publishing?"

Short of tearing things down entirely, we do think that specific changes to the incentive structure are in order. It has been argued elsewhere that societally impactful scientific insights should be treated as open-source software artifacts ([Liem and Demetriou, 2023](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=10173886)). Open review platforms like this one are a step in the right direction but we could go further. In the open-source software development space, those who review a piece of software often end up contributing to it, because they face the right incentives: not only will they most likely be users of that improved piece of software but also receive credit for their contribution (as they should). The idea of moving from authorship to contributorship is not as radical as it may sound ([Smith, 1997](https://www.bmj.com/content/315/7110/696.short)) but thirty years ago one could have argued that we are lacking the right technology for this. Today this argument is much harder to buy in the face of blossoming open-source software ecosystems. Considering that researchers in the computer science field are no strangers to papers with long author lists, we think it is reasonable to assume they would generally welcome such a paradigm shift. 

> "Should we be more welcoming of negative results?" 

Continuing the argument above, a system that leans more towards contributorship is typically much more welcoming of negative results: software bugs are just part of the process and joint ownership means joint responsibility for positive and negative outcomes.
 
> "Should we set up more venues specifically devoted to reproducing and analyzing past claims?"

Yes, we think that reproducibility challenges, for example, are a step in the right direction. But many legacy issues associated with treating 

> "Should we offer compensation for reviewing?" 

Contributorship can provide a natural form of non-pecuniary compensation for reviewing (open-source communities testify to this). As researchers, we are financially compensated for producing research. Perhaps we simply need to get to a point where reviews can lead to (accredited) contributorship. Reviewer awards are a step in the right direction. But given the sheer size of today's venues, they are an improbable, risky outcome for reviewers and hence unlikely to provide strong enough incentives.  

> "All these questions have been asked before, but do they become more salient or more urgent with respect to modern evolutions in generative AI?"

Considering that the existing incentive structure has repeatedly moved researchers to employ generative AI to deal with the tasks and pressures they are facing, we think these questions have certainly become more urgent. 

# Reviewer jMr8

We thank the reviewer for the detailed and thoughtful review. 

## Section 2.1 - Limitations of Inverse Problem

The reviewer pointed out that the "inverse problem is ill-conditioned and could not recover the perfect signal in theory." The authors agree that this can indeed be seen as a form of inverse problem and common caveats such as non-uniqueness and instability apply ([Haltmeier and Nguyen, 2020](https://arxiv.org/abs/2006.03972)). We use $\ell^2$-regularization for the linear probe (ridge regression), which corresponds to Tikhonov regularization in the context of approximation theory ([Björkström, 2001](https://www2.math.su.se/matstat/reports/seriea/2000/rep5/report.pdf)). We confess that we did not carefully consider the parameter choice for the ridge penalty, nor has this been carefully studied in the broader literature on linear probes for mechanistic interpretability to the best of our knowledge.
Indeed we would expect that the signal would not perfectly be recovered in theory given the compression of the data. However, some signal would indeed imperfectly be recovered, with a closer approximation of perfection in recovery the 'better' the model is. Given that LLMs are essentially compressing textual information, and that LLMs have demonstrated a high capability of doing so, we of course expect an inverse attempt to recover the signal to be partially successful. What is not to be expected is an interpretation that this imperfect yet-close-enough-to-accurate signal recovery is interpreted as the system having a 'mental model' of the earth, and thus showing 'sparks' of general intelligence - especially when 'general intelligence' and even 'intelligence' are narrowly defined in this space, and when there are ideal conditions for misinterpretation of results in the form of anthropomorphism and cognitive bias. 
Thus, we still think that this simple experiment in Section 2.1 describes the problem of running linear probes on LLMs reasonably well at a high level. If anything, the challenges pointed out by the reviewer therefore cast further doubt on this practice. We will add a note or paragraph on this in the final manuscript. Furthermore, we would like to point out that even in the case of imperfect yet-close-enough-to-accurate signal recovery, this is not to be interpreted as the system having a 'mental model' of the earth, and thus showing 'sparks' of general intelligence - especially when 'general intelligence' and even 'intelligence' are narrowly defined in this space, and when there are ideal conditions for misinterpretation of results in the form of anthropomorphism and cognitive bias.

## Section 2.3.2. - The Parrot Test

Section 2.3.2. applied a 'strong' test to the hypothesis that LLMs 'understand'. We show results that one might interpret as the models having some understanding of economics, and being able to imperfectly forecast economic indicators - a parallel to the notion that model output correlating with latitude longitude is an indication that the model ‘understands’ geography, or has a ‘mental’ model of the globe. 
The 'spurious' correlation then, is in the interpretation that the 'accuracy' of the output of the model correlating with economic indicators is a cue that the model is understanding - or more specifically that the correlation between the output of the model and the 'ground truth' economic indicators is 'caused' by the model's understanding of the text. 
We then show that the model fails to 'understand' when we apply a simple linguistic transformation to our experiment. 
## Section 3.2 - Anthropomorphism and AI
Your recommendation that we better ground sec 3.2 in the current research space is well-noted. Reflecting on your comment, we think there are at least 3 ways to reach a better understanding:
Acknowledgement: researchers should consider acknowledging our tendency to anthropomorphize either in a dedicated ‘limitations’ section or when discussing results.
Stronger testing: researchers should refrain from drawing premature conclusions about AGI, unless these conclusions are based on strong hypothesis tests.
Epistemologically robust standards: we call for more precise definitions of terms like ‘intelligence’ and ‘AGI’, and iterations over how we will measure them
We feel an appropriate discussion would require more room than is allocated in the paper. Nevertheless, we can attempt to summarize our position in the main body or perhaps in the appendix.
For a slightly more detailed discussion, please see our comments below:
A crucial first step is to acknowledge openly that such cognitive bias and tendency towards anthropomorphism exists, and is especially likely in this space. While it may remain in the language that we use (e.g. phrases like the model ‘thinks’, ‘understands’, etc.), behaviorally it must be addressed in the research space, e.g. with acknowledgment in ‘limitations’ sections of papers, and in the interpretation of results in our discussion sections. This may lead to more broad attempts to address anthropomorphism, e.g. with better research designs and analyses.
A second step, and one such research design element, is stronger testing which we attempt in this paper. Intelligence is only ‘indirectly’ measurable in automated systems as it is in humans. Thus we must also acknowledge that claims of ‘AGI’ deserve scrutiny. If such a claim is easily negated with a simple change in language, we take this as a sign that the field is only weakly testing its claims. We note that this does not mean that researchers are not making great efforts to test their models - leaderboards on Huggingface, and the limitless torrent of papers on LLMs would speak to the contrary. However, these tests may not be appropriate indicators that a system is approaching AGI, but rather that a system is performing well on some narrowly defined task and accompanying dataset. Thus, if we are to approach AGI with our work, we must have a strong test - a risky test that a system is likely to fail. In fields like psychology where the concept of intelligence itself emerged, discussions of appropriately strong tests for claims abound - we require the same rigor in this field as well. 
Thirdly, and more broadly, we see a need for more epistemologically robust standards in the work itself to combat anthropomorphism. To this end, further inspiration may be drawn from psychology - ‘construct’ oriented definitions of important concepts, and a focus on achieving better indirect measurement. While computer science has traditionally not been a hypothesis-driven field that deals with indirect and imperfect measurements, psychology research methods have evolved specifically for these purposes. Applying this to the study of AGI requires first a somewhat-agreed upon definition not only on what ‘AGI’ is, but also how it would manifest itself - with the understanding that it may appear differently than intelligence does in humans. 
Computer science tends to borrow heavily from the rather vague definition of Spearman that it is about ‘generally solving problems (e.g. [Goertzel, 2014](https://sciendo.com/article/10.2478/jagi-2014-0001)) - if we wish to take advantage of this definition, we might attempt to already claim that the LLMs achieve this: the models weren’t designed for any specific task, and yet can be used to assist in many tasks. At the same time, our work shows that this does not mean that these models ‘understand’ the problems they are solving, nor can they formulate the problems in the first place. If our current assessments are all inspired by how we measure intelligence in humans, and models are trained on the material of the tests and appropriate responses, assessing ‘AGI’ in this way is simply inappropriate. We don’t have a good answer to this last point - but are excited to consider what a field that acknowledges its own biases can accomplish in this regard. 

## Other Modalities

From what we have observed in the past, we think the concerns we have raised may apply to many applications, but are urgent in the context of LLMs. Many people attribute our ability to understand, to our ability to communicate through language. Recent implementations as chat bots, e.g. Replika and Chat GPT, as well as virtual assistants (Alexa, Cortana) have afforded a kind of interaction that resembles linguistic exchanges with other humans. We can certainly imagine there is some degree of anthropomorphizing with any ‘AI’ technology that has some apparent behavior e.g. self-driving cars. But as language is an all too obvious feature distinguishing us from other species, it is not surprising that LLMs have so far been anthropomorphized more so than foundation models with other modalities - language is what makes them an ingredient in the ‘perfect storm’. 

# Reviewer AGDV

We thank the reviewer for the detailed and thoughtful review. 

## Revised Abstract

The reviewer pointed out that the abstract was not optimally aligned with the paper and we agree that there is some room for improvement. We propose this more detailed and longer revised version:

“Developments in the field of AI in general, and Large Language Models (LLMs) in particular, have created a ‘perfect storm’ for observing ‘sparks’ of Artificial General Intelligence (AGI) that are spurious. Like simpler models, LLMs distill representations in their latent embeddings that have been shown to correlate with meaningful phenomena. Nonetheless, the correlation of such representations has often been linked to human-like intelligence in the latter but not the former. We probe models of varying degrees of sophistication including random projections, matrix decompositions, deep autoencoders and transformers: all of them successfully distill knowledge and yet none of them develop true understanding. Specifically, we show that embeddings of a language model fine-tuned on central bank communications can make meaningful predictions, via correlations with unseen economic variables, such as price inflation. However, we then show that inflation is also predicted for nonsense prompts about growing and shrinking bird populations (‘dovelation’). We therefore argue that patterns in latent spaces are spurious sparks of (AGI). Additionally, we review literature from the social sciences that shows that humans are prone to seek patterns and anthropomorphize. We, therefore, argue that both the methodological setup and common public image of AI are ideal for the misinterpretation that correlations between model representations and some variables of interest are 'caused' by the model's understanding of underlying ‘ground truth’ relationships. We therefore call for the academic community to exercise extra caution, and to be keenly aware of principles of academic integrity, in interpreting and communicating about AI research outcomes.”

## Cognitive Biases

While we appreciate the feedback, we would like some clarity on what precisely this reviewer means by ‘a bit poorly argued’? We do indeed see that 366-371 can be cut. We may have included details that summarize more of the material than is essential to the discussion, and perhaps trimming would make our arguments more clear. Nevertheless, we feel the included text summarizes work that has shown antecedents to two forms of cognitive bias. These sections aim to show how the presence of the antecedents makes the current situation with ‘AI’ tools in general and with LLMs in specific, a perfect storm for misinterpretation. We would happily take on any suggestions as to how this can be clearer and better argued. 

## Figure 3

We apologize for the somewhat sloppy figure description and appreciate the reviewer’s suggestions. The solid line is just a smooth trendline, which we added to highlight that we find the expected negative relationship between estimated errors and network depth. On second thought, and in light of your feedback, we will simply remove these trend lines to avoid confusion. We will adjust the figure caption as follows: “Out-of-sample root mean squared error (RMSE) for the linear probe plotted against FOMC-RoBERTa’s n-th layer for different indicators. The values correspond to averages computed across cross-validation folds, where we have used an expanding window approach to split the time series. As expected, we observe that model performance tends to be higher (average prediction errors are lower) for layers near the end of the transformer model.”

Although the errors are indeed low compared to baseline autoregressive models (as we explain in lines 237-249), this chart is not the most obvious choice to drive home that particular point. We chose to highlight this chart nonetheless because it is more consistent with the presentations chosen in the related literature on mechanistic interpretability. It is common to show that probe performance improves for layer activations near the output layer, which illustrates that “neural networks are really about distilling computationally useful *representations*” as opposed to *information contents* ([Alain and Bengio, 2018](https://arxiv.org/abs/1610.01644)). 

## Confusing Title

We appreciate this take and understand that this sort of title may not be appealing to everyone. To avoid any confusion about a potential typo, we have addressed this in the revised abstract. We are still keen to keep the title as is unless the reviewer(s) find(s) it critical that we adjust it.

# Reviewer 8XDk

We thank the reviewer for the detailed and thoughtful review. 

## Other Works

It was not so much the work by Gurnee and Tegmark itself but the subsequent buzz around it on social media that served as a catalyst for this work. Further, we explain that public perception of the state of AI work has been shown to be mediated via experts (e.g. [Neri et al., 2020](https://link.springer.com/article/10.1007/s00146-019-00924-9). We explain that the situation is ripe for over-interpretation to show that expert perceptions are susceptible to cognitive biases, and have downstream consequences. 

The paper itself, in particular the revised version, is much more cautious about drawing premature conclusions than some of the public communications that followed (we cite and refer to both versions explicitly in the paper). Many related works are also free of grandiose conclusions and instead highlight the benefits of mechanistic interpretability that we also acknowledge in our work (e.g. [Nanda et al., 2023](https://arxiv.org/pdf/2309.00941.pdf); [Gurnee et al., 2023](https://arxiv.org/pdf/2305.01610.pdf); [Li et al., 2023](https://arxiv.org/pdf/2210.13382.pdf)). But as we explain in the paper, certain incentives and pressures may lead researchers to blow their scientific findings out of proportion outside of academia itself. The general situation surrounding LLMs makes biased interpretations of results particularly likely. And if experts over-interpret their findings, public perception will be influenced by this as well. This is what we want to caution against and why we call for more explicit acknowledgment of known limitations, stronger tests and more epistemologically robust standards.

Another broadly related field investigates the capacity of LLMs to reason causally. Here, too, there is an opportunity to over-interpret the finding of causal knowledge as causal understanding. Recent work has shown that LLMs can indeed correctly predict causal relationships and this may have practical use cases ([Kıcıman et al., 2023](https://arxiv.org/abs/2305.00050)). But it has also been argued and demonstrated that current LLMs are mere ‘weak causal parrots’ ([Zečević et al., 2023](https://arxiv.org/abs/2308.13067)).

## Guidance from the Social Science(s) 

We appreciate the points raised here by the reviewer, in particular, that “the sudden pivot to the social science literature review” caused confusion. Drawing these kinds of connections is always challenging in interdisciplinary works and we will try to address this in the manuscript. In particular, with respect to the experiments, we will make it more clear that:

We would not expect that anyone would anthropomorphize simple random projections and PCA, although both can be used to distill meaningful representations.
And yet, researchers do fall into that trap for more sophisticated models, in particular LLMs. 

> “Could you clarify how the social science review provides guidance for the ML community with respect to your specific experiments and more broadly?”

Present work resulted from an interdisciplinary team with backgrounds in the computational and social sciences. By including a social science review we strengthen our argument that the risks of bias and over-interpretation in humans have consistently been evidenced in academic literature (as opposed to merely stating our opinion on the matter). 

At the very least, we hope that our review can help researchers in the ML community (ourselves included) to become more aware of our human tendencies to seek patterns and confirmation and to anthropomorphize. While these tendencies are often useful, they can also harm communities, perhaps especially research communities, and bias public perception. Further, we hope that, through acknowledgment that all humans are subject to cognitive bias and that the current situation in AI research in general, and with LLMs in particular, is ripe for at least two forms of bias, a focus can be placed on combating it through more severe tests of AGI-related hypotheses, and research design. 