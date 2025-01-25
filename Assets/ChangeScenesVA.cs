using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ChangeScenesVA : MonoBehaviour
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
    public void GoToSceneHy()
    {
        SceneManager.LoadScene(5);
    }
}
