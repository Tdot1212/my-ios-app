import { fetch } from 'undici';

async function testAPI() {
  try {
    console.log('Testing trends API...');
    
    // Test with default parameters
    const response = await fetch('http://localhost:3000/api/trends');
    const data = await response.json();
    
    console.log('✅ API Response:');
    console.log(`Status: ${response.status}`);
    console.log(`Items count: ${data.items?.length || 0}`);
    console.log(`Fetched at: ${data.fetchedAt}`);
    
    if (data.items && data.items.length > 0) {
      console.log('\n📰 Sample items:');
      data.items.slice(0, 3).forEach((item, i) => {
        console.log(`${i + 1}. [${item.source}] ${item.title}`);
      });
    }
    
    if (data.error) {
      console.log('❌ Error:', data.error);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testAPI();
