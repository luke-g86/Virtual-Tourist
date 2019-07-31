# Virtual Tourist read me

This is an internal project, created during **Udacity’s iOS Nanodegree**. User can drop  a pin for the desired area on the map and which allows user to drop a Pin onto the map for which pictures from Flickr API are being downloaded and presented in a form of picutres' grid. 

## Installation

Just use **git clone** to copy entire project

```
git clone https://github.com/luke-g86/Virtual-Tourist.git
cd ../Virtual-Tourist
open Virtual-Tourist.xcodeproj
```

## More about the project

Project uses MapKit and utilizes Flickr API to
* Search photos for the given location
* Download and parse data from the API
* Save data into the database made with the CoreData framework
* Data in relation one-to-many are being presented in the form of CollectionView
* User can re-fetch new set of pictures from API and / or DELETE pictures directly from CollectionView. 
* All requests are being performed in threads to not obstruct an  app snappiness.



