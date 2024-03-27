## Revised Abstract

We have a more detailed and longer revised version of the abstract ready that covers the following points:

- Like simpler models, LLMs distill meaningful representations in their latent embeddings.
- We probe various models (highlight 'dovelation' example) to show that all of them distill knowledge and yet none of them develop true understanding.
- Backed by our social science review, we argue that humans are prone to interpret patterns in latent spaces as (spurious) sparks of AGI.

## Cognitive Biases

While we appreciate the feedback, we would like some clarity on what precisely this reviewer is looking for. We do indeed see that 366-371 can be cut. We may have too much detail, and perhaps trimming would make our arguments more clear. Nevertheless, we feel the included text summarizes work that has shown antecedents to two forms of cognitive bias. These sections aim to show how the presence of the antecedents makes the current situation with ‘AI’ tools in general and with LLMs in specific, a perfect storm for misinterpretation. We would happily take on any suggestions as to how this can be clearer and better argued. 

## Figure 3

We apologize for the sloppy figure description. The solid line is just a smooth trendline, which we added to highlight that we find the expected negative relationship between estimated errors and network depth ([Alain and Bengio, 2018](https://arxiv.org/abs/1610.01644)). In light of your feedback, we will simply remove these trend lines to avoid confusion. We will adjust the figure caption as follows: “Out-of-sample root mean squared error (RMSE) for the linear probe plotted against FOMC-RoBERTa’s n-th layer for different indicators. The values correspond to averages computed across cross-validation folds, where we have used an expanding window approach to split the time series. As expected, we observe that model performance tends to be higher (average prediction errors are lower) for layers near the end of the transformer model.” The errors are indeed low compared to baseline autoregressive models (as we explain in lines 237-249).

## Confusing Title

We appreciate this take and understand that this sort of title may not be appealing to everyone. To avoid any confusion about a potential typo, we have addressed this in the revised abstract. We are still keen to keep the title as is unless the reviewer(s) find(s) it critical that we adjust it.
