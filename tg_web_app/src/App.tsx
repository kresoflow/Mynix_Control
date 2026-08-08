import { useState, useEffect } from 'react';
import './index.css';

interface Category {
  id: string;
  name: string;
  color: string;
}

const CATEGORIES: Category[] = [
  { id: '1', name: 'Напитки', color: '#F59E0B' },
  { id: '2', name: 'Шаурма', color: '#EF4444' },
  { id: '3', name: 'Хот-доги', color: '#10B981' },
  { id: '4', name: 'Соусы', color: '#8B5CF6' },
  { id: '5', name: 'Гарниры', color: '#3B82F6' },
  { id: '6', name: 'Пицца', color: '#EC4899' },
];

function App() {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate lightning fast load (React is instantly ready, we just show a skeleton for 0.5s for effect)
    setTimeout(() => {
      setLoading(false);
    }, 500);
  }, []);

  return (
    <div style={{ padding: '16px', minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#F59E0B' }}>Меню</h1>
        <div style={{ padding: '8px', background: 'var(--surface)', borderRadius: '12px' }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
          </svg>
        </div>
      </header>

      {loading ? (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
          {[1, 2, 3, 4, 5, 6].map(i => (
            <div key={i} style={{ 
              background: 'var(--surface)', 
              height: '140px', 
              borderRadius: '20px',
              animation: 'pulse 1.5s infinite'
            }} />
          ))}
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
          {CATEGORIES.map(cat => (
            <div key={cat.id} style={{
              background: 'var(--surface)',
              borderRadius: '20px',
              padding: '24px 16px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '12px',
              boxShadow: '0 4px 24px rgba(0,0,0,0.2)',
              border: '1px solid var(--border)'
            }}>
              <div style={{
                background: cat.color,
                width: '48px',
                height: '48px',
                borderRadius: '16px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#fff'
              }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path>
                  <polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline>
                  <line x1="12" y1="22.08" x2="12" y2="12"></line>
                </svg>
              </div>
              <span style={{ fontSize: '15px', fontWeight: 600 }}>{cat.name}</span>
            </div>
          ))}
        </div>
      )}

      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: .5; }
        }
      `}</style>
    </div>
  );
}

export default App;
