using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ChangeSceneWelcome : MonoBehaviour
{
    public void GoToSceneFB()
    {
        SceneManager.LoadScene(1);
    }
    public void GoToSceneAA()
    {
        SceneManager.LoadScene(2);
    }
    public void GoToSceneVA()
    {
        SceneManager.LoadScene(3);
    }
    public void GoToSceneTH()
    {
        SceneManager.LoadScene(0);
    }
    public void GoToSceneHy()
    {
        SceneManager.LoadScene(5);
    }
}
