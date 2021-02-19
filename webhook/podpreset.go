package main

import (
	"context"
	"sync"

	"github.com/golang/glog"
	"k8s.io/apimachinery/pkg/api/meta"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/client/config"

	settingsapi "github.com/jpeeler/podpreset-crd/pkg/apis/settings/v1alpha1"
)

var crdClient client.Client
var muCrdClient sync.RWMutex

func getCrdClient() client.Client {
	muCrdClient.Lock()
	defer muCrdClient.Unlock()

	config, err := config.GetConfig()
	if err != nil {
		glog.Fatal(err)
	}
	crdclient, err := client.New(config, client.Options{Scheme: scheme})
	if err != nil {
		glog.Fatal(err)
	}

	return crdclient
}

func listPodPresetWithRetry(ns string) ([]settingsapi.PodPreset, error) {
	l, err := listPodPresets(ns)

	// if the crd client was created before the CRD was applied - try to do a retry with a fresh client
	if meta.IsNoMatchError(err) {
		crdClient = getCrdClient()
		l, err = listPodPresets(ns)
	}
	return l, err
}

func listPodPresets(ns string) ([]settingsapi.PodPreset, error) {
	muCrdClient.RLock()
	defer muCrdClient.RUnlock()

	list := &settingsapi.PodPresetList{}
	err := crdClient.List(context.TODO(), list, &client.ListOptions{Namespace: ns})
	return list.Items, err
}
