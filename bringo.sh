#!/bin/bash
carrefour_id="carrefour_vulcan"
categoriesFile=`mktemp`
tempFinal=`mktemp`
taxonsFile=`mktemp`
discounted_taxonsFile=`mktemp`
csvFinal="$PWD/$carrefour_id.csv"

if [ ! -f /usr/bin/jq ] ; then
echo "JSON parser not installed."
echo "Install jq package."
exit
fi

if [ ! -z $1 ]; then
carrefour_id=$1
fi

echo "RAION,CATEGORIE,BRAND,NUME,PRET,POZA" >$csvFinal

echo "== Generating Categories =="
echo " "
echo "Configured store: $carrefour_id"
echo -n "Working...  "
curl -s "https://apis.bringo.ro/public/v1/ro/stores/$carrefour_id/categories?limit=999&page=1" | jq -r '._embedded.items[] | [ .translations[].slug ] | @csv' | sed 's/"//g' >$categoriesFile

for categ in `cat $categoriesFile`; do
curl -s "https://apis.bringo.ro/public/v1/ro/stores/$carrefour_id/categories/$categ?limit=999&page=1" | jq -r '._embedded.items[] | [ .translations[].slug ] | @csv' | sed 's/"//g' >>$taxonsFile

curl -s "https://apis.bringo.ro/public/v1/ro/stores/carrefour_vulcan/discounted-taxons?limit=999&page=1" | jq -r '._embedded.items[] | [ .translations[].slug ] | @csv' | sed 's/"//g' >$discounted_taxonsFile

done
echo "Done."
echo " "
echo "== Main categories =="
echo " "

for i in `cat $taxonsFile`; do 
tempCat=`mktemp`
echo -n "Processing $i...    "
curl -s "https://apis.bringo.ro/public/v1/ro/stores/$carrefour_id/taxons/$i/products?limit=1500&page=1" | jq -r '._embedded.items[] | [ .product.isleName, .product.familyName, .product.brandName, .product.name, .channelPricings.US_WEB.price/100, "https://storage.googleapis.com/bringoimg/web/cache/sylius_large/" + .product.images[0].path ] | @csv' >$tempCat
num=`cat $tempCat | wc -l`
echo "$num products found."
cat $tempCat >> $tempFinal
rm $tempCat
done

echo " "
echo "== Discounted categories =="
echo " "

for i in `cat $discounted_taxonsFile`; do
tempCat=`mktemp`
echo -n "Processing $i...    "
curl -s "https://apis.bringo.ro/public/v1/ro/stores/$carrefour_id/discounted-taxons/$i/products?limit=1500&page=1" | jq -r '._embedded.items[] | [ .product.isleName, .product.familyName, .product.brandName, .product.name, .channelPricings.US_WEB.price/100, "https://storage.googleapis.com/bringoimg/web/cache/sylius_large/" + .product.images[0].path ] | @csv' >$tempCat
num=`cat $tempCat | wc -l`
echo "$num products found."
cat $tempCat >> $tempFinal
rm $tempCat
done

cat $tempFinal | sort -u  >>$csvFinal
sed -i 's/\,\"https:\/\/storage.googleapis.com\/bringoimg\/web\/cache\/sylius_large\/"/,/' $csvFinal

echo " "
nrprod=`cat $csvFinal | wc -l`
echo "Found $nrprod products."
echo "Done. Generated file: $csvFinal"

rm $tempFinal
rm $taxonsFile
rm $categoriesFile
rm $discounted_taxonsFile
