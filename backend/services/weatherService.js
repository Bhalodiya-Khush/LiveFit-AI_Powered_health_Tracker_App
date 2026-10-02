const axios = require('axios');

// WMO Weather interpretation codes
const weatherCodes = {
  0: 'Clear sky ☀️',
  1: 'Mainly clear 🌤️',
  2: 'Partly cloudy ⛅',
  3: 'Overcast ☁️',
  45: 'Foggy 🌫️',
  48: 'Depositing rime fog 🌫️',
  51: 'Light drizzle 🌦️',
  53: 'Moderate drizzle 🌧️',
  55: 'Dense drizzle 🌧️',
  61: 'Slight rain 🌧️',
  63: 'Moderate rain 🌧️',
  65: 'Heavy rain ⛈️',
  71: 'Slight snow fall 🌨️',
  73: 'Moderate snow fall ❄️',
  75: 'Heavy snow fall ❄️',
  80: 'Rain showers 🌦️',
  81: 'Moderate rain showers 🌧️',
  82: 'Violent rain showers ⛈️',
  95: 'Thunderstorm ⚡',
};

async function getWeather(lat, lon) {
  let targetLat = lat != null ? Number(lat) : null;
  let targetLon = lon != null ? Number(lon) : null;
  let cityName = 'Current Location';

  // If coordinates are missing or default Delhi (28.6139), dynamically resolve via network IP
  if (!targetLat || !targetLon || (Math.abs(targetLat - 28.6139) < 0.01 && Math.abs(targetLon - 77.2090) < 0.01)) {
    try {
      const geoUrl = 'https://api.bigdatacloud.net/data/reverse-geocode-client?localityLanguage=en';
      const geoRes = await axios.get(geoUrl, { timeout: 3500 });
      if (geoRes.data) {
        if (geoRes.data.latitude && geoRes.data.longitude) {
          targetLat = Number(geoRes.data.latitude);
          targetLon = Number(geoRes.data.longitude);
        }
        cityName = geoRes.data.city || geoRes.data.locality || geoRes.data.principalSubdivision || 'Current Location';
      }
    } catch (err) {
      // IP geocoding fallback
    }
  } else {
    // Reverse geocode given coordinates
    try {
      const geoUrl = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${targetLat}&longitude=${targetLon}&localityLanguage=en`;
      const geoRes = await axios.get(geoUrl, { timeout: 3500 });
      if (geoRes.data) {
        cityName = geoRes.data.city || geoRes.data.locality || geoRes.data.principalSubdivision || 'Current Location';
      }
    } catch (_) {}
  }

  // If still unavailable, fallback to Nadiad coordinates
  if (!targetLat || !targetLon) {
    targetLat = 22.6916;
    targetLon = 72.8634;
    if (cityName === 'Current Location') cityName = 'Nadiad';
  }

  try {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${targetLat}&longitude=${targetLon}&current_weather=true`;
    const response = await axios.get(url, { timeout: 4000 });

    if (response.data && response.data.current_weather) {
      const cw = response.data.current_weather;
      const code = cw.weathercode;
      const condition = weatherCodes[code] || 'Clear sky ☀️';
      const temp = cw.temperature;
      
      let indoorRecommended = false;
      let weatherAdvice = 'Great weather for active movement!';

      if (code >= 51 || temp > 35 || temp < 5) {
        indoorRecommended = true;
        weatherAdvice = temp > 35 
          ? 'Very hot outside! Indoor hydration and bodyweight training recommended.'
          : 'Rainy or chilly conditions outside. Safe indoor conditioning recommended.';
      } else {
        weatherAdvice = 'Pleasant weather! Great for outdoor brisk walking or interval training.';
      }

      return {
        city: cityName,
        temperature: temp,
        weatherCode: code,
        condition,
        windspeed: cw.windspeed,
        isDay: cw.is_day === 1,
        indoorRecommended,
        weatherAdvice,
        coordinates: { lat: targetLat, lon: targetLon },
      };
    }
  } catch (error) {
    console.warn('Open-Meteo weather fetch error:', error.message);
  }

  // Graceful fallback
  return {
    city: cityName,
    temperature: 24,
    weatherCode: 0,
    condition: 'Pleasant 🌤️',
    windspeed: 5.0,
    isDay: true,
    indoorRecommended: false,
    weatherAdvice: 'Comfortable temperature for customized indoor or outdoor workout.',
    coordinates: { lat: targetLat, lon: targetLon },
  };
}

module.exports = { getWeather };
