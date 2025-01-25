# AMIS

## Overview
The **Audiovisual Multimodal Interaction Suite** features the **AMIS Dataset**, a comprehensive multimodal audiovisual dataset. The dataset includes synchronized recordings in the form of Talking-Head Videos, Full-Body Videos, Personalized Animated Avatars, and Volumetric Avatars, with content structured into monologues and conversations. Complementing the dataset, the **AMIS Studio** Unity demonstrator provides a platform for exploring the dataset's content in VR. Together, AMIS Dataset and AMIS Studio offer a resource for research in immersive and multimodal communication.


The link to the corresponding paper:

The link to access the dataset, metadata, and demo video of AMIS Studio:
[https://avtshare01.rz.tu-ilmenau.de/amis/](https://avtshare01.rz.tu-ilmenau.de/amis/)

	
## AMIS Studio

### Prerequisites
- **Unity Version**: The project was developed using Unity 2022.3.27f1 with the XR Interaction Toolkit. Please ensure you have this or a compatible version installed.
- **Dependencies**:  
  All necessary dependencies and packages are already included in the Unity project:
  - The **cc_unity_tools_3D package** is required for personalized animated avatars, also available at [soupday/cc_unity_tools_3D](https://github.com/soupday/cc_unity_tools_3D.git).
  - The **Unity volumetric video player package** is included with the dataset and the Unity project for volumetric avatars.

### Steps to Set Up
1. Clone this repository
2. Open the project in Unity.
3. Build the project for your target platform (e.g., Windows, Oculus).
4. add the following videos from the dataset to the video folder for the demo
```
Talking-head videos EF2_EF1_1 and 2, EM_M1
Full-body videos EM_EF2_1 and 2, EM_M1
```
5. add the following files from the dataset to the ReconstructedStreams folder for the demo
```
Audio, Vol. Avatar byte stream and stream info JSON file for
EF1_EM_1 and 2, EM_M1
```
6. Run the application and explore the scenes:
   - Use the VR menu to switch between scenes.

### Animated Avatars scene
1. To explore other personalized avatars and animations, drag the avatar from the dataset to the scene.
2. In the associated Animator Controller panel, drag and drop the respective animation file. Make sure the connection between the Entry node and the Animation Node is automatically created.
3. Drag and drop the associated AudioClip in the Audio Source component of the Avatar Unity object.
4. Press play

### Volumetric Avatars scene
1. Activate/Deactivate the desired VolumetricAvatar game object.
2. Every recording is represented by the associated byte streams and a stream info JSON file which loads the stream and audio in the Unity scene.
3. Both should be added to the Resources folder with the associated audio file.
4. Add the path to the JSON file in the volumetric_resource_json_file_path entry in the Volumetric Video Updater component of the child object of the main player.
5. Make sure the Audio Source component is selected.
6. The audiovisual sync can be adjusted by the offset_in_seconds entry in the JSON
6. Press play.

### 2D Videos
1. Add the desired talking-head or full-body video to the Videos folder in Resources.
2. In the Video Player component of the TV panels game objects, drag and drop the desired video clip.
3. Press play.


## AMIS Dataset
### File Structure
```
AMIS/
|-- dataset/
|   |-- audios/
|       |-- Conversations/
|       |-- Monologues/
|   |-- full-body-videos/
|       |-- Conversations/
|       |-- Monologues/
|   |-- personalized-avatars/
|       |-- Avatars/
|       |-- Animations/
|           |-- Conversations/
|           |-- Monologues/
|   |-- talking-head-videos/
|       |-- Conversations/
|       |-- Monologues/
|   |-- volumetric-videos/
|       |-- Conversations/
|       |-- Monologues/
|-- utils/
|   |-- Reactions/
|       |-- (12 segmented reaction videos)
|   |-- transcripts/
|       |-- (Monologue and Conversation transcripts)
|   |-- BGremoval.md
|   |-- monologue_annotation.csv
|   |-- Multiparty_Grid_Generator.py
|   |-- participants.csv
|   |-- vrsys-unity-volumetric-video-player-v3.unitypackage
|   |-- DEMO_AMIS_Studio.mp4

```
## Nomenclature

### Monologues
Each actor performed all 9 monologues (M1 to M9). File naming follows this structure:
```
[ActorID]_M[MonologueNumber].ext
```
Actors are coded as:
- **EF1**: Female Actor 1.
- **EF2**: Female Actor 2.
- **EM**: Male Actor.

Example:
```
EF1_M1.mp4
EF1_M2.mp4
...
EF1_M9.mp4
EF2_M1.mp4
...
EM_M9.mp4
```

### Conversations
There are 6 conversations, and each pair of actors has two recordings with a reversed speaker order. File naming follows this structure:
```
[ActorID1]_[ActorID2]_[SpeakerOrder].ext
```
- **[SpeakerOrder]**: 
  - `1`: Indicates the first speaker's recording.
  - `2`: Indicates the second speaker's recording.

Examples:
```
EF1_EF2_1.mp4  # Conversation between EF1 and EF2, first speaker EF1.
EF1_EF2_2.mp4  # Conversation between EF1 and EF2, second speaker EF2.
EF1_EM_1.mp4   # Conversation between EF1 and EM, first speaker EF1.
EF1_EM_2.mp4   # Conversation between EF1 and EM, second speaker EM.
...
EM_EF2_1.mp4   # Conversation between EM and EF2, first speaker EM.
EM_EF2_2.mp4   # Conversation between EM and EF2, second speaker EF2.
```

## Disclaimer

The volumetric byte stream for the avatar of actor **EF1** in the conversation file **EF1_EF2_1** experienced a loss of camera streams after 17 seconds.



## How to Cite
If you use this dataset or demonstrator in your work, please cite as follows:
```bibtex

```

## Contact
For support or questions, please contact:
- **Email**: abhinav.bhattacharya@tu-ilmenau.de

