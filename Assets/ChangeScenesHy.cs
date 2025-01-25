using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ChangeScenesHy : MonoBehaviour
{
    public void GoToSceneFB()
    {
        SceneManager.LoadScene(1);
    }
    public void GoToSceneAA()
    {
        SceneManager.LoadScene(2);
    }
    public void GoToSceneTH()
    {
        SceneManager.LoadScene(0);
    }
    public void GoToSceneWelcome()
    {
        SceneManager.LoadScene(4);
    }
    public void GoToSceneVA()
    {
        SceneManager.LoadScene(3);
    }

}
