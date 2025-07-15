import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [status, setStatus] = useState('Present');
  const [token, setToken] = useState('');
  const [attendance, setAttendance] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const validStatuses = ['Present', 'Absent', 'Late'];

  const handleSubmit = async () => {
    if (!status || !validStatuses.includes(status)) {
      setError('Please select a valid attendance status');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const response = await axios.post(`${process.env.REACT_APP_API_URL}/attendance`, {
        date: new Date().toISOString().split('T')[0],
        status
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });

      setSuccess(response.data.message || 'Attendance submitted successfully!');
      loadAttendance();
      
    } catch (err) {
      console.error('Error submitting attendance:', err);
      if (err.response?.data?.detail) {
        setError(err.response.data.detail);
      } else if (err.response?.status === 401) {
        setError('Session expired. Please login again.');
        setToken('');
      } else {
        setError('Failed to submit attendance. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const loadAttendance = async () => {
    if (!token) return;

    try {
      const res = await axios.get(`${process.env.REACT_APP_API_URL}/attendance`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setAttendance(res.data);
    } catch (err) {
      console.error('Error loading attendance:', err);
      if (err.response?.status === 401) {
        setError('Session expired. Please login again.');
        setToken('');
      } else {
        setError('Failed to load attendance records.');
      }
    }
  };

  const checkHealth = async () => {
    try {
      const res = await axios.get(`${process.env.REACT_APP_API_URL}/health`);
      console.log('Health check:', res.data);
    } catch (err) {
      console.error('Health check failed:', err);
    }
  };

  useEffect(() => {
    const url = new URL(window.location.href);
    const fragment = new URLSearchParams(url.hash.substring(1));
    const _token = fragment.get("access_token");
    
    if (_token) {
      setToken(_token);
      loadAttendance();
      // Clear the URL fragment for security
      window.history.replaceState({}, document.title, window.location.pathname);
    }

    // Check API health on load
    checkHealth();
  }, []);

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const formatDateTime = (dateTimeString) => {
    return new Date(dateTimeString).toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const clearMessages = () => {
    setError('');
    setSuccess('');
  };

  return (
    <div style={{ 
      padding: '2em', 
      maxWidth: '800px', 
      margin: '0 auto',
      fontFamily: 'Arial, sans-serif'
    }}>
      <h1 style={{ 
        color: '#333', 
        textAlign: 'center',
        marginBottom: '2em',
        borderBottom: '2px solid #4CAF50',
        paddingBottom: '0.5em'
      }}>
        📚 Student Attendance System
      </h1>
      
      {!token ? (
        <div style={{ textAlign: 'center', padding: '3em' }}>
          <h2 style={{ color: '#666', marginBottom: '1em' }}>Please Login to Continue</h2>
          <a 
            href="http://localhost:8080/realms/school/protocol/openid-connect/auth?client_id=frontend&response_type=token&redirect_uri=http://localhost:3000"
            style={{
              backgroundColor: '#4CAF50',
              color: 'white',
              padding: '12px 24px',
              textDecoration: 'none',
              borderRadius: '4px',
              fontSize: '16px',
              display: 'inline-block',
              transition: 'background-color 0.3s'
            }}
            onMouseOver={(e) => e.target.style.backgroundColor = '#45a049'}
            onMouseOut={(e) => e.target.style.backgroundColor = '#4CAF50'}
          >
            🔑 Login with Keycloak
          </a>
        </div>
      ) : (
        <div>
          <div style={{ 
            backgroundColor: '#f9f9f9', 
            padding: '2em', 
            borderRadius: '8px',
            marginBottom: '2em',
            border: '1px solid #ddd'
          }}>
            <h2 style={{ color: '#333', marginBottom: '1em' }}>📝 Submit Today's Attendance</h2>
            
            {error && (
              <div style={{ 
                backgroundColor: '#ffebee', 
                color: '#c62828', 
                padding: '12px', 
                borderRadius: '4px',
                marginBottom: '1em',
                border: '1px solid #ffcdd2'
              }}>
                ❌ {error}
                <button 
                  onClick={clearMessages}
                  style={{ 
                    background: 'none', 
                    border: 'none', 
                    color: '#c62828',
                    cursor: 'pointer',
                    float: 'right',
                    fontSize: '16px'
                  }}
                >
                  ×
                </button>
              </div>
            )}
            
            {success && (
              <div style={{ 
                backgroundColor: '#e8f5e8', 
                color: '#2e7d32', 
                padding: '12px', 
                borderRadius: '4px',
                marginBottom: '1em',
                border: '1px solid #c8e6c9'
              }}>
                ✅ {success}
                <button 
                  onClick={clearMessages}
                  style={{ 
                    background: 'none', 
                    border: 'none', 
                    color: '#2e7d32',
                    cursor: 'pointer',
                    float: 'right',
                    fontSize: '16px'
                  }}
                >
                  ×
                </button>
              </div>
            )}
            
            <div style={{ marginBottom: '1em' }}>
              <label style={{ 
                display: 'block', 
                marginBottom: '0.5em',
                fontWeight: 'bold',
                color: '#333'
              }}>
                Attendance Status:
              </label>
              <select 
                value={status} 
                onChange={e => setStatus(e.target.value)}
                style={{
                  width: '100%',
                  padding: '10px',
                  borderRadius: '4px',
                  border: '1px solid #ddd',
                  fontSize: '16px',
                  backgroundColor: 'white'
                }}
              >
                {validStatuses.map(statusOption => (
                  <option key={statusOption} value={statusOption}>
                    {statusOption === 'Present' && '✅ Present'}
                    {statusOption === 'Absent' && '❌ Absent'}
                    {statusOption === 'Late' && '⏰ Late'}
                  </option>
                ))}
              </select>
            </div>
            
            <button 
              onClick={handleSubmit}
              disabled={loading}
              style={{
                backgroundColor: loading ? '#ccc' : '#4CAF50',
                color: 'white',
                padding: '12px 24px',
                border: 'none',
                borderRadius: '4px',
                fontSize: '16px',
                cursor: loading ? 'not-allowed' : 'pointer',
                width: '100%',
                transition: 'background-color 0.3s'
              }}
            >
              {loading ? '⏳ Submitting...' : '📤 Submit Attendance'}
            </button>
          </div>

          <div style={{ 
            backgroundColor: '#f9f9f9', 
            padding: '2em', 
            borderRadius: '8px',
            border: '1px solid #ddd'
          }}>
            <h3 style={{ 
              color: '#333', 
              marginBottom: '1em',
              borderBottom: '1px solid #ddd',
              paddingBottom: '0.5em'
            }}>
              📊 My Attendance Records
            </h3>
            
            {attendance.length === 0 ? (
              <p style={{ 
                color: '#666', 
                textAlign: 'center',
                fontStyle: 'italic',
                padding: '2em'
              }}>
                No attendance records found. Submit your first attendance above!
              </p>
            ) : (
              <div style={{ maxHeight: '400px', overflowY: 'auto' }}>
                <table style={{ 
                  width: '100%', 
                  borderCollapse: 'collapse',
                  backgroundColor: 'white',
                  borderRadius: '4px',
                  overflow: 'hidden'
                }}>
                  <thead>
                    <tr style={{ backgroundColor: '#f0f0f0' }}>
                      <th style={{ 
                        padding: '12px', 
                        textAlign: 'left',
                        borderBottom: '1px solid #ddd'
                      }}>
                        Date
                      </th>
                      <th style={{ 
                        padding: '12px', 
                        textAlign: 'left',
                        borderBottom: '1px solid #ddd'
                      }}>
                        Status
                      </th>
                      <th style={{ 
                        padding: '12px', 
                        textAlign: 'left',
                        borderBottom: '1px solid #ddd'
                      }}>
                        Submitted
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {attendance.map((record, index) => (
                      <tr key={index} style={{ 
                        borderBottom: index < attendance.length - 1 ? '1px solid #eee' : 'none'
                      }}>
                        <td style={{ padding: '12px' }}>
                          {formatDate(record.date)}
                        </td>
                        <td style={{ padding: '12px' }}>
                          <span style={{
                            padding: '4px 8px',
                            borderRadius: '4px',
                            fontSize: '14px',
                            backgroundColor: 
                              record.status === 'Present' ? '#e8f5e8' :
                              record.status === 'Absent' ? '#ffebee' :
                              record.status === 'Late' ? '#fff3e0' : '#f0f0f0',
                            color:
                              record.status === 'Present' ? '#2e7d32' :
                              record.status === 'Absent' ? '#c62828' :
                              record.status === 'Late' ? '#ef6c00' : '#666'
                          }}>
                            {record.status === 'Present' && '✅ Present'}
                            {record.status === 'Absent' && '❌ Absent'}
                            {record.status === 'Late' && '⏰ Late'}
                          </span>
                        </td>
                        <td style={{ 
                          padding: '12px',
                          fontSize: '14px',
                          color: '#666'
                        }}>
                          {record.created_at ? formatDateTime(record.created_at) : 'N/A'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
