# OpenFace2Synchrony

## Description

This R script provides a bridge between [OpenFace 2.0](https://github.com/TadasBaltrusaitis/OpenFace) (Amos et al., 2016) outputs and subsequent nonverbal synchrony calculations either using [Altmann's (2013)](https://github.com/10101-00001) approach or [rMEA](https://github.com/kleinbub/rMEA) (Kleinbub & Ramseyer, 2021). 

The main function is based on OpenDBM's [head_pose_dist function](https://github.com/AiCure/open_dbm/blob/master/opendbm/dbm_lib/dbm_features/raw_features/movement/head_motion.py) (AiCure, 2023). However, the function was altered and the scope for calculation narrowed. OpenDBM’s head_post_dist function filters out frames that detect a face with a confidence of .2 or higher, the present function uses a threshold of .95 instead. Additionally, the Euclidean distance was only calculated when the frame before the current one (index-1) showed a confidence of at least .95 as well. This was done in order to avoid onset peaks of movement that resulted from erroneous calculations of the Euclidean distance based on preceding frames with low confidence ratings and therefore unreliable calculations of the head position. 

Unfortunately, neural networks like OpenFace 2.0 may detect faces, and therefore movement, were there are no actual faces present, or where they are partially obscured by a hand. Hence, even frames with high confidence ratings may produce erroneous movement calculations. The highest values tend to appear at camera onset after a blue screen or when a hand is masking the face. Given that, in the case of head movements, outliers are not only valid but also suggestive of behaviors (e.g., head nodding during agreement or shaking for disagreement), it is difficult to determine a threshold that only removes false positives.  

To tackle this problem, values should be filtered for movement that is physiologically possible and probable. The measured Euclidean distances can be understood as an average change in radians on all three axes. Healthy control participants usually reach mean velocities of 365°/s in horizontal head shakes (y-axis; Röijezon et al., 2010), with a maximum of 457°/sec. Notably, peak velocities differ in vertical (770°/s) and horizontal (1100°/s) and torsional (250°/s) head movement (Aw et al., 1996; Grossman et al., 1988).  It is physiologically not possible to move at those speeds on all axes simultaneously. For instance, if you shake your head horizontally, vertical movement will be much smaller. Considering a scenario where a person simultaneously moved their head by 180° on all three axes, this would involve, for example, looking down and to the left while tilting the head to the left at time one and looking up and to the right while tilting the head to the right at time two. It is reasonable to assume that this motion can occur within a one-second interval. Based on this estimation of a maximum of 180° per second on all three axes simultaneously, a corresponding threshold of 0.2 radians per frame appeared suitable for distinguishing physiologically plausible movement from potential false positives.

OpenFace 2.0 estimates radians per frame. Using a camera that captures content at 25 frames per second, 180° per second translate to 0.1256637 radians per frame. Assuming a head pose facing directly at the camera without any tilt at frame 1, yaw, pitch and roll obtain a value of 0. Moving the head 0.125 radians to frame 2 on all axes, they obtain all the same value of 0.125. Calculating the Euclidean distance based on these values gives .21 as result. Hence, a threshold of .2 will effectively filter out movement that goes beyond movement with 180°/s on all axis simultaneously.
If a person violently shook their head and actually reached 457°/s, that would result in a Euclidean distance of .3. However, this is arguably unlikely in a recorded experimental conversation task. In one sample, the .2 threshold filtered out only 0.05% of frames on average but excluded frames showing movement as high as 8.5 radians per frame (12175°/sec) which reflects impossible head movement. The small number of excluded frames may indicate two things: either applying a 95% confidence filter in the movement calculation a priori may sort out outliers well enough already or our threshold is set too high. 

This is a first attempt to filter out implausible movement captured by OpenFace 2.0. A more robust threshold needs to be established by comparing plausible movement across various situations. 

## Notes

The script is written in R which may be more accessible to psychologists. It assists with the management of relativley large data sets, cuts computing times short using foreach loops and generates outputs that are usable for common synchrony calculations. However, the change in confidence threshold is easily acichievable in the original code by OpenDBM.

## Contributors to this project

This script was developed in close collaboration with the following researchers:

Uwe Altmann (MSB), Mina Ameli (DFKI), Philipp Müller (DFKI), Fabrizio Nunnari (DFKI), Janet Wessler (DFKI)

## References

AiCure. (2023). OpenDBM. GitHub. https://github.com/AiCure/open_dbm

Altmann, U. (2013). MEA: Motion Energy Analysis. GitHub. https://github.com/10101-00001/MEA

Amos, B., Ludwiczuk, B., & Satyanarayanan, M. (2016). Openface: A general-purpose face recognition library with mobile applications. CMU School of Computer Science, 6(2), 20.

Aw, S. T., Haslwanter, T., Halmagyi, G. M., Curthoys, I. S., Yavor, R. A., & Todd, M. J. (1996). Three-dimensional vector analysis of the human vestibuloocular reflex in response to high-acceleration head rotations. I. Responses in normal subjects. Journal of Neurophysiology, 76(6), 4009–4020.

Grossman, G. E., Leigh, R. J., Abel, L. A., Lanska, D. J., & Thurston, S. E. (1988). Frequency and velocity of rotational head perturbations during locomotion. Experimental Brain Research, 70(3), 470–476. https://doi.org/10.1007/BF00247595

Kleinbub, J. R., & Ramseyer, F. T. (2021). rMEA: An R package to assess nonverbal synchronization in motion energy analysis time-series. Psychotherapy Research, 31(6), 817–830. https://doi.org/10.1080/10503307.2020.1844334

Röijezon, U., Djupsjöbacka, M., Björklund, M., Häger-Ross, C., Grip, H., & Liebermann, D. G. (2010). Kinematics of fast cervical rotations in persons with chronic neck pain: A cross-sectional and reliability study. BMC Musculoskeletal Disorders, 11. https://doi.org/10.1186/1471-2474-11-222

## Appendix

### Deriving the .2 movement threshold
```
library(pracma)

# radians per frame
rpf <- deg2rad(180)/25

x1 = 0
y1 = 0
z1 = 0

x2 = rpf
y2 = rpf
z2 = rpf

sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)+(z2-z1)*(z2-z1))

```

