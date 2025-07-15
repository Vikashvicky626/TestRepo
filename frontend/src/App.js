import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [status, setStatus] = useState('');
  const [token, setToken] = useState('');
  const [attendance, setAttendance] = useState([]);

  const handleSubmit = async () => {
    await axios.post(`${process.env.REACT_APP_API_URL}/attendance`, {
      date: new Date().toISOString().split('T')[0],
      status
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    alert("Attendance submitted!");
    loadAttendance();
  };

  const loadAttendance = async () => {
    const res = await axios.get(`${process.env.REACT_APP_API_URL}/attendance`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    setAttendance(res.data);
  };

  useEffect(() => {
    const url = new URL(window.location.href);
    const fragment = new URLSearchParams(url.hash.substring(1));
    const _token = fragment.get("access_token");
    if (_token) {
      setToken(_token);
      loadAttendance();
    }
  }, []);

  return (
    <div style={{ padding: '2em' }}>
      <h2>Daily Attendance</h2>
      {!token ? <a href="http://localhost:8080/realms/school/protocol/openid-connect/auth?client_id=frontend&response_type=token&redirect_uri=http://localhost:3000">Login with Keycloak</a> : (
        <>
          <input placeholder="Present/Absent" value={status} onChange={e => setStatus(e.target.value)} />
          <button onClick={handleSubmit}>Submit</button>
          <h4>My Records</h4>
          <ul>{attendance.map((a, i) => <li key={i}>{a.date} - {a.status}</li>)}</ul>
        </>
      )}
    </div>
  );
}

export default App;
